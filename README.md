# Used Book Exchange

Requires Ruby 1.8.7. The `ferret` gem causes errors in Ruby 1.9.2.

## Commands

### Run tests

    rake

### Start server

    ./script/server

### Local console

    ./script/console

### Remote console

    heroku run ./script/console

### Remote backups

Create a backup:

    heroku pgbackups:capture

List all backups:

    heroku pgbackups

Download a backup (replace `b001`):

    curl -o latest.dump `heroku pgbackups:url b001`

Restore a backup locally (omit `--clean` unless the local database already existed):

    pg_restore --verbose --clean --no-acl --no-owner -h localhost -d ube_development latest.dump

Restore a backup remotely (replace `HEROKU_POSTGRESQL_BROWN` and `a001`):

    heroku pgbackups:restore HEROKU_POSTGRESQL_BROWN a001

## Heroku Stack

    heroku stack

## Soft Reset

There must be a single seller with the name `Book Exchange`.
