package utils;

import java.sql.Connection;
import java.sql.DriverManager;

public class Connexion {
    private Connection connection;

    public Connexion() throws Exception {
        Class.forName("org.postgresql.Driver");
        setConnection(DriverManager.getConnection("jdbc:postgresql://localhost:5432/recherche", "postgres", "root"));
        connection.setAutoCommit(false);
    }

    public Connection getConnection() {
        return connection;
    }

    public void setConnection(Connection connection) {
        this.connection = connection;
    }
}