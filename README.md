# adwords

## Install

```
$ bundle install
```

## Setting Database

- create database.

```
mysql> create database adwords;
```

- create table.

```
$ mysql adwords < schema.sql
```

- database configuration.

```
$ export APP_DB_HOST='127.0.0.1'
$ export APP_DB_PORT=3306
$ export APP_DB_DATABASE='adwords'
$ export APP_DB_USER='mysql_user'
$ export APP_DB_PASS='mysql_password'
```

## Run

```
$ bundle exec ./adwords.rb KEYWORD
```
