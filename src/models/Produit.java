package models;

import utils.Connexion;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Vector;

public class Produit {
    private int id;
    private String designation;
    private double prix;
    private double qualite;
    private Categorie categorie;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getDesignation() {
        return designation;
    }

    public void setDesignation(String designation) {
        this.designation = designation;
    }

    public double getPrix() {
        return prix;
    }

    public void setPrix(double prix) {
        this.prix = prix;
    }

    public double getQualite() {
        return qualite;
    }

    public void setQualite(double qualite) {
        this.qualite = qualite;
    }

    public Categorie getCategorie() {
        return categorie;
    }

    public void setCategorie(Categorie categorie) {
        this.categorie = categorie;
    }

    public static Vector<Produit> recherche(String phrase, int limit, Connection connection) throws SQLException {
        boolean is_connected = false;
        try {
            if (connection == null) {
                is_connected = true;
                connection = new Connexion().getConnection();
            }
            StringBuilder sql = new StringBuilder("SELECT * from recherche_produit(?) ");
            if (limit > 0) {
                sql.append("limit ?");
            }
            try (PreparedStatement preparedStatement = connection.prepareStatement(sql.toString())) {
                preparedStatement.setString(1, phrase);
                if (limit > 0) {
                    preparedStatement.setInt(2, limit);
                }
                System.out.println(preparedStatement);
                try (ResultSet resultSet = preparedStatement.executeQuery()) {
                    Vector<Produit> produits = new Vector<>();
                    while (resultSet.next()) {
                        Produit produit = new Produit();
                        produit.setId(resultSet.getInt("id"));
                        produit.setDesignation(resultSet.getString("designation"));
                        Categorie categorie1 = new Categorie();
                        categorie1.setNom(resultSet.getString("categorie"));
                        produit.setCategorie(categorie1);
                        produit.setQualite(resultSet.getDouble("qualite"));
                        produit.setPrix(resultSet.getDouble("prix"));
                        produits.add(produit);
                    }
                    return produits;
                }
            }
        } catch (Exception e) {
            assert connection != null;
            throw new RuntimeException(e);
        } finally {
            if (is_connected) {
                assert connection != null;
                connection.close();
            }
        }
    }
}
