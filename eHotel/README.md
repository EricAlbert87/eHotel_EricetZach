# eHotel Application

## Start the Application (With Make)

1. Open a terminal and go to the project folder.

```bash
cd /path/to/eHotel
```

2. Run setup and start commands.

Linux:
```bash
make setup
make build
make run
```

macOS:
```bash
make -f Makefile.mac setup
make -f Makefile.mac build
make -f Makefile.mac run
```

3. Open the app in your browser.

http://localhost:8080

## Start the Application (No Makefile)

1. Open a terminal and go to the project folder.

```bash
cd /path/to/eHotel
```

2. Install dependencies.

Linux (Ubuntu/Debian):
```bash
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk maven postgresql postgresql-contrib
sudo systemctl start postgresql
```

macOS (Homebrew):
```bash
brew install openjdk@21 maven postgresql
brew services start postgresql
```

3. Create and initialize the database.

Linux:
```bash
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='ehotels'" | grep -q 1 || sudo -u postgres createdb ehotels
sudo -u postgres psql -d ehotels < database/ehotels_postgresql.sql
```

macOS:
```bash
psql -U postgres -h localhost -c "ALTER USER postgres WITH PASSWORD 'postgres';"
psql -U postgres -h localhost -tAc "SELECT 1 FROM pg_database WHERE datname='ehotels'" | grep -q 1 || createdb -U postgres -h localhost ehotels
psql -U postgres -h localhost -d ehotels < database/ehotels_postgresql.sql
```

4. Build the application jar.

```bash
mvn clean package
```

5. Start the server.

```bash
java -jar target/ehotel-app-1.0-SNAPSHOT-jar-with-dependencies.jar
```

6. Open the app in your browser.

http://localhost:8080
