# eHotel Installation Guide

Complete setup instructions for the eHotel application on Linux and macOS.

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation on Linux/Ubuntu](#installation-on-linuxubuntu)
- [Installation on macOS](#installation-on-macos)
- [Running the Application](#running-the-application)
- [Accessing the Frontend](#accessing-the-frontend)
- [Database Management](#database-management)
- [Troubleshooting](#troubleshooting)

---

## System Requirements

### Common Requirements
- **Java**: JDK 21 or later
- **Maven**: 3.6 or later
- **PostgreSQL**: 12 or later
- **curl** or a web browser for testing

### Minimum Disk Space
- ~500 MB for dependencies, build artifacts, and database

---

## Installation on Linux/Ubuntu

### Quick Setup (One Command)

```bash
cd eHotel
make setup
```

This single command will:
1. Install Java 21, Maven, and PostgreSQL
2. Start the PostgreSQL service
3. Create the `ehotels` database
4. Import the sample data

### Manual Setup (Step by Step)

#### 1. Install Dependencies

```bash
make install
```

Or manually:
```bash
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk maven postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

#### 2. Initialize Database

```bash
make db-init
```

Or manually:
```bash
cd /tmp
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
sudo -u postgres createdb ehotels
sudo -u postgres psql -d ehotels < /path/to/database/ehotels_postgresql.sql
```

#### 3. Build the Application

```bash
make build
```

Alternatively:
```bash
mvn clean package
```

#### 4. Run the Application

```bash
make run
```

Or:
```bash
java -jar target/ehotel-app-1.0-SNAPSHOT-jar-with-dependencies.jar
```

---

## Installation on macOS

### Quick Setup (One Command)

```bash
cd eHotel
make -f Makefile.mac setup
```

This single command will:
1. Install Java 21, Maven, and PostgreSQL via Homebrew
2. Start the PostgreSQL service
3. Create the `ehotels` database
4. Import the sample data

### Prerequisites for macOS

**Homebrew Installation** (if not already installed):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Manual Setup (Step by Step)

#### 1. Install Dependencies

```bash
make -f Makefile.mac install
```

Or manually:
```bash
brew install openjdk@21 maven postgresql
brew services start postgresql
```

#### 2. Initialize Database

```bash
make -f Makefile.mac db-init
```

If your local PostgreSQL admin role is not `postgres`, run:

```bash
make -f Makefile.mac db-init DB_ADMIN=$(whoami)
```

Or manually:
```bash
psql -U postgres -h localhost -c "ALTER USER postgres WITH PASSWORD 'postgres';"
psql -U postgres -h localhost -c "CREATE DATABASE ehotels;"
psql -U postgres -h localhost -d ehotels < database/ehotels_postgresql.sql
```

#### 3. Build the Application

```bash
make -f Makefile.mac build
```

Or:
```bash
mvn clean package
```

#### 4. Run the Application

```bash
make -f Makefile.mac run
```

Or:
```bash
java -jar target/ehotel-app-1.0-SNAPSHOT-jar-with-dependencies.jar
```

---

## Running the Application

### Using Make (Recommended)

**Linux:**
```bash
make start          # Build and run
# or
make build && make run  # Build, then run separately
```

**macOS:**
```bash
make -f Makefile.mac start          # Build and run
# or
make -f Makefile.mac build && make -f Makefile.mac run
```

### Direct Java Command

```bash
java -jar target/ehotel-app-1.0-SNAPSHOT-jar-with-dependencies.jar
```

The application will start on **port 8080**.

### Expected Output

```
Server started on port 8080
```

The server is ready when you see this message.

---

## Accessing the Frontend

### In a Web Browser

Once the application is running, open your browser and navigate to:

```
http://localhost:8080
```

### API Endpoints (curl)

Test the API with curl:

```bash
# Get all rooms
curl http://localhost:8080/api/rooms

# Get all clients
curl http://localhost:8080/api/clients

# Get current reservations
curl http://localhost:8080/api/reservations

# Create a reservation
curl -X POST "http://localhost:8080/api/reservations" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "clientId=1&chambreId=1&dateDebut=2026-05-01&dateFin=2026-05-05"
```

---

## Database Management

### Database Credentials

- **Host**: `localhost:5432`
- **Database**: `ehotels`
- **Username**: `postgres`
- **Password**: `postgres`

### Connect to Database

**Linux:**
```bash
sudo -u postgres psql -d ehotels
```

**macOS:**
```bash
psql -U postgres -h localhost -d ehotels
```

### View Database Schema

```sql
-- Connect to ehotels database first

-- List all tables
\dt

-- View table structure
\d client
\d chambre
\d reservation
\d location

-- View all reservations
SELECT * FROM reservation;

-- View all locations
SELECT * FROM location;
```

### Reset Database to Sample Data

```bash
# Linux
make db-init

# macOS
make -f Makefile.mac db-init
```

Or manually:
```bash
# Backup (optional)
pg_dump -U postgres ehotels > ehotels_backup.sql

# Restore fresh data
psql -U postgres -d ehotels < database/ehotels_postgresql.sql
```

---

## Makefile Commands Reference

### Linux Makefile

| Command | Purpose |
|---------|---------|
| `make help` | Show all available commands |
| `make install` | Install Java, Maven, PostgreSQL |
| `make db-init` | Create database and import data |
| `make setup` | Run install and db-init |
| `make build` | Compile and package the application |
| `make run` | Start the application |
| `make start` | Build and run the application |
| `make deploy-copy SERVER_USER=ubuntu SERVER_HOST=1.2.3.4` | Copy JAR to remote server |
| `make deploy-run SERVER_USER=ubuntu SERVER_HOST=1.2.3.4` | Run on remote server |
| `make deploy SERVER_USER=ubuntu SERVER_HOST=1.2.3.4` | Full deployment |

### macOS Makefile

Use `make -f Makefile.mac` instead of `make`:

```bash
make -f Makefile.mac help
make -f Makefile.mac doctor
make -f Makefile.mac setup
make -f Makefile.mac build
make -f Makefile.mac start
```

---

## Troubleshooting

### Port 8080 Already in Use

**Error**: `Address already in use`

**Solution**:
```bash
# Linux
sudo lsof -i :8080
# Kill the process
sudo kill -9 <PID>
```

```bash
# macOS
lsof -i :8080
# Kill the process
kill -9 <PID>
```

### PostgreSQL Connection Failed

**Error**: `connection refused` or `Peer authentication failed`

**Solution**:

1. Run the built-in diagnostic:
   ```bash
   make -f Makefile.mac doctor
   ```

2. Verify PostgreSQL is running:
   ```bash
   # Linux
   sudo systemctl status postgresql
   
   # macOS
   brew services list | grep postgresql
   ```

3. Restart PostgreSQL:
   ```bash
   # Linux
   sudo systemctl restart postgresql
   
   # macOS
   brew services restart postgresql
   ```

4. If your admin role is not `postgres`, initialize with your local admin role:
   ```bash
   make -f Makefile.mac db-init DB_ADMIN=$(whoami)
   ```

5. Verify database exists:
   ```bash
   # Linux
   sudo -u postgres psql -l | grep ehotels
   
   # macOS
   psql -U postgres -h localhost -l | grep ehotels
   ```

### Maven Build Fails

**Error**: `mvn: command not found` or compilation errors

**Solution**:

1. Verify Maven installation:
   ```bash
   mvn --version
   ```

2. If not installed, reinstall:
   ```bash
   # Linux
   sudo apt-get install maven
   
   # macOS
   brew install maven
   ```

3. Clear Maven cache and rebuild:
   ```bash
   mvn clean install -U
   ```

### Java Version Mismatch

**Error**: `unsupported class file format` or `invalid source release`

**Solution**:

1. Check Java version:
   ```bash
   java --version
   ```

2. Should show Java 21 or later. If not:
   ```bash
   # Linux
   sudo apt-get install openjdk-21-jdk
   
   # macOS
   brew install openjdk@21
   ```

### Database Import Failed

**Error**: `psql: error` or SQL syntax errors

**Solution**:

1. Verify SQL file exists and is readable:
   ```bash
   ls -la database/ehotels_postgresql.sql
   ```

2. Check PostgreSQL user permissions:
   ```bash
   # Linux
   sudo -u postgres psql -d ehotels -c "SELECT 1;"
   
   # macOS
   psql -U postgres -h localhost -d ehotels -c "SELECT 1;"
   ```

3. Re-import the database:
   ```bash
   # Linux
   make db-init
   
   # macOS
   make -f Makefile.mac db-init
   ```

### Frontend Not Loading

**Error**: Blank page or `Connection refused`

**Solution**:

1. Verify server is running:
   ```bash
   curl http://localhost:8080
   ```

2. Check server logs for errors

3. Clear browser cache and reload (Ctrl+Shift+Del or Cmd+Shift+Del)

4. Try different browser

---

## Additional Resources

- **Main README**: [README.md](README.md)
- **Testing Guide**: [TESTING_GUIDE.md](../TESTING_GUIDE.md)
- **Project Structure**: See [pom.xml](pom.xml) for dependencies and configuration

---

## Support

For issues or questions:
1. Check this troubleshooting section
2. Review the database initialization script: `database/ehotels_postgresql.sql`
3. Examine application logs in the terminal output
4. Check PostgreSQL logs:
   ```bash
   # Linux
   sudo tail -f /var/log/postgresql/postgresql-*.log
   
   # macOS
   tail -f /usr/local/var/log/postgres.log
   ```

