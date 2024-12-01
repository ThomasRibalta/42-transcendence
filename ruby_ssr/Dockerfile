FROM ruby:3.1

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["sh", "-c", "rerun --background --dir /app ruby app.rb"]
