package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import models.Produit;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Vector;

@WebServlet(name = "Recherche", value = "/Recherche")
public class RechercheServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.getRequestDispatcher("index.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String phrase = request.getParameter("phrase");
        String[] mots = phrase.split(" ");
        int limit = 0;
        for (String mot : mots) {
            try {
                limit = Integer.parseInt(mot);
            } catch (Exception ignored) {

            }
        }
        try {
            Vector<Produit> produits = Produit.recherche(phrase, limit, null);
            request.setAttribute("produits", produits);
            doGet(request, response);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}