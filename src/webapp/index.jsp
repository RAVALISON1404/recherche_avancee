<%@ page import="java.util.Vector" %>
<%@ page import="models.Produit" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<% Vector<Produit> produits = (Vector<Produit>) request.getAttribute("produits"); %>
<!doctype html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport"
		  content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
	<meta http-equiv="X-UA-Compatible" content="ie=edge">
	<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
	<title>Document</title>
</head>
<body>
<header>
	<nav class="navbar">
		<div class="navbar-brand">
			<div class="navbar-brand">
				<div class="navbar-item">
					<h3 class="title">
						Recherche
					</h3>
				</div>
			</div>
		</div>
		<div class="navbar-menu">
			<div class="navbar-end">
				<div class="navbar-item">
					<form action="Recherche" method="post" class="field has-addons has-addons-centered">
						<label class="control">
							<input type="text" name="phrase" placeholder="Recherchez ici..." class="input">
						</label>
						<div class="control">
							<button type="submit" class="button is-info">
								Rechercher
							</button>
						</div>
					</form>
				</div>
			</div>
		</div>
	</nav>
</header>
<% if (produits != null) { %>
<section class="section">
	<%--	<div class="container"></div>--%>
	<table class="table is-fullwidth is-bordered">
		<thead>
		<tr>
			<th></th>
			<th>Designation</th>
			<th>Categorie</th>
			<th>Qualite</th>
			<th>Prix</th>
		</tr>
		</thead>
		<tbody>
		<% for (int i = 0; i < produits.size(); i++) { %>
		<tr>
			<td>
				<%= i + 1%>
			</td>
			<td>
				<%= produits.get(i).getDesignation() %>
			</td>
			<td>
				<%= produits.get(i).getCategorie().getNom() %>
			</td>
			<td>
				<%= produits.get(i).getQualite() %>
			</td>
			<td>
				<%= produits.get(i).getPrix() %>
			</td>
		</tr>
		<% } %>
		</tbody>
	</table>
</section>
<% } %>
</body>
</html>