# TV Guide Application

This is a Perl-based TV guide application running in a Docker container.

## Running the Application

To run the application:

```bash
docker-compose up -d
```

The application will be available at http://localhost:8080

## Database Files

The database files are stored in Berkeley DB format and are accessible in the following locations:

- Database files: `./db_data/` directory
  - channels.db - TV channels database
  - programs.db - TV programs database
  - categories.db - Program categories database
  - schedule.db - TV schedule database

- Image files: `./img_data/` directory

## Viewing DB Files

To examine the database files, you can:

1. Use Berkeley DB tools if installed locally
2. Access the container shell and use Perl scripts:

```bash
docker-compose exec web /bin/bash
cd /usr/local/apache2/cgi-bin
# Write simple script to read DB files
perl -MDB_File -e 'tie %h, "DB_File", "/usr/local/apache2/data/channels.db"; print "$_: $h{$_}\n" for keys %h; untie %h'
```

The databases will persist between container restarts since they're mounted as volumes. 