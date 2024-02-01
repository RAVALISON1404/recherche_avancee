import models.Produit;

import java.sql.SQLException;
import java.util.Vector;

public class Main {
    public static void main(String[] args) throws SQLException {
        Vector<Produit> produits = Produit.recherche("meilleur qualite alim", null);
        for (Produit produit : produits) {
            System.out.println(produit.getDesignation());
        }
    }
}