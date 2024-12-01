require 'pg'
require 'connection_pool'

class Database
  @pool = ConnectionPool.new(size: 5, timeout: 5) do
    PG.connect(
      dbname: ENV['POSTGRES_DB'],
      user: ENV['POSTGRES_USER'],
      password: ENV['POSTGRES_PASSWORD'],
      host: 'postgres',
      port: 5432
    )
  end
  
  @logger = Logger.new

  def self.pool
    @pool
  end

  def self.logger
    @logger
  end

  def self.execute(query)
    pool.with do |conn|
      conn.exec(query)
    end
  end

  def self.get_all_from_table(table_name)
    query = "SELECT * FROM #{table_name} WHERE deleted_at IS NULL"
    result = execute(query)
    result.map { |row| row }
  end

  def self.insert_into_table(table_name, data)
    columns = data.keys.join(", ")
    values = data.values.map { |value| "'#{value}'" }.join(", ")
    query = "INSERT INTO #{table_name} (#{columns}) VALUES (#{values}) RETURNING *"
    begin
      result = execute(query)
      result.first
    rescue PG::Error => e
      @logger.log('Database', "Error inserting into table #{table_name}: #{e.message}")
    end
  end

  def self.get_one_element_from_table(table_name, or_conditions = {}, and_conditions = {})
    or_where_clauses = or_conditions.map { |column, value| "#{column} = $#{or_conditions.keys.index(column) + 1}" }.join(' OR ') unless or_conditions.empty?
    and_where_clauses = and_conditions.map { |column, value| "#{column} = $#{or_conditions.size + and_conditions.keys.index(column) + 1}" }.join(' AND ') unless and_conditions.empty?

    where_clauses = []
    where_clauses << "(#{or_where_clauses})" if or_where_clauses
    where_clauses << and_where_clauses if and_where_clauses
    where_clauses << "deleted_at IS NULL"

    query = "SELECT * FROM #{table_name} WHERE #{where_clauses.join(' AND ')}"

    values = or_conditions.values + and_conditions.values

    result = pool.with { |conn| conn.exec_params(query, values) }
    result.map { |row| row }
  end
  

  def self.update_table(table_name, data, or_conditions = {}, and_conditions = {})
    set_clause = data.map { |key, value| "#{key} = '#{value}'" }.join(", ")

    or_where_clauses = or_conditions.map { |column, value| "#{column} = $#{or_conditions.keys.index(column) + 1}" }.join(' OR ') unless or_conditions.empty?
    and_where_clauses = and_conditions.map { |column, value| "#{column} = $#{or_conditions.size + and_conditions.keys.index(column) + 1}" }.join(' AND ') unless and_conditions.empty?

    where_clauses = []
    where_clauses << "(#{or_where_clauses})" if or_where_clauses
    where_clauses << and_where_clauses if and_where_clauses
    where_clauses << "deleted_at IS NULL"

    query = "UPDATE #{table_name} SET #{set_clause} WHERE #{where_clauses.join(' AND ')}"
    values = or_conditions.values + and_conditions.values

    begin
      pool.with { |conn| conn.exec_params(query, values) }
      true
    rescue PG::Error => e
      Logger.new.log('Database', "Error updating table #{table_name}: #{e.message}")
      false
    end
  end

  def self.get_paginated_element_from_table(table_name, page, per_page, order=nil)
    page = page.to_i
    offset = (page - 1) * per_page
    query = "SELECT * FROM #{table_name} WHERE deleted_at IS NULL "
    if order
      query += "ORDER BY #{order} "
    end
    query += "LIMIT #{per_page} OFFSET #{offset}"
    result = execute(query)
    result.map { |row| row }
  end

  def self.get_user_stats_and_games(user_id)
    query = <<-SQL
      SELECT 
          ph.rank_points,
          ph.nb_win,
          ph.nb_win_tournament,
          ph.nb_lose,
          ph.nb_game,
          COALESCE(
              JSON_AGG(
                  JSON_BUILD_OBJECT(
                      'id', p.id,
                      'player_1_id', p.player_1_id,
                      'player_2_id', p.player_2_id,
                      'type', p.type,
                      'state', p.state,
                      'rank_points', p.rank_points,
                      'player_1_score', p.player_1_score,
                      'player_2_score', p.player_2_score,
                      'created_at', p.created_at
                  )
              ) FILTER (WHERE p.id IS NOT NULL), 
              '[]'
          ) AS games
      FROM 
          _user u
      JOIN 
          _pongHistory ph ON u.id = ph.user_id
      LEFT JOIN 
          _pong p ON u.id = p.player_1_id OR u.id = p.player_2_id
      WHERE 
          u.id = #{user_id} AND p.deleted_at IS NULL AND ph.deleted_at IS NULL AND u.deleted_at IS NULL
      GROUP BY 
          ph.rank_points, ph.nb_win, ph.nb_lose, ph.nb_game, ph.nb_win_tournament;
    SQL
    
    begin
      result = execute(query)
      stats = result.map { |row| row }.first
      
      stats["games"] = JSON.parse(stats["games"]) if stats["games"].is_a?(String)
      
      return stats
    rescue PG::Error => e
      @logger.log('Database', "Error retrieving stats and games for user #{user_id}: #{e.message}")
      {}
    end
  end
  
end
