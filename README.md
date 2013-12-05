# Used Book Exchange

Requires Ruby 1.8.7.

## Commands

### Run tests

    rake

### Start server

    ./script/server

### Local console

    ./script/console

### Remove console

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

## Heroku Stack

    heroku stack

Continue to use REE 1.8.7 on the Bamboo stack. The Cedar stack only supports the slower MRI 1.8.7, and migrating to Ruby 1.9.2 may break Ferret.

## Soft Reset

There must be a single seller with the name `Book Exchange`
