from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import logging
import csv
from io import StringIO

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Import dishes from CSV data into Firestore'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        
        
        categories_data = {
            'Entrées': {
                'id': 'cat_entrees',
                'sous_categories': {
                    'Soupes et Potages': 'scat_soupes',
                    'Salades et Crudités': 'scat_salades',
                    'Spécialités Chaudes': 'scat_chaudes',
                    'Spécialités Froides': 'scat_froides'
                }
            },
            'Plats': {
                'id': 'cat_plats',
                'sous_categories': {
                    'Sandwichs et Burgers': 'scat_sandwichs',
                    'Cuisine Traditionnelle': 'scat_traditionnelle',
                    'Poissons et Fruits de Mer': 'scat_poissons',
                    'Viandes': 'scat_viandes',
                    'Végétarien': 'scat_vegetarien'
                }
            },
            'Accompagnements': {
                'id': 'cat_accompagnements',
                'sous_categories': {
                    'Féculents': 'scat_feculents',
                    'Légumes': 'scat_legumes'
                }
            },
            'Boissons': {
                'id': 'cat_boissons',
                'sous_categories': {
                    'Boissons Chaudes': 'scat_chaudes_boissons',
                    'Boissons Froides': 'scat_froides_boissons'
                }
            },
            'Desserts': {
                'id': 'cat_desserts',
                'sous_categories': {
                    'Crèmes et Mousses': 'scat_cremes',
                    'Fruits et Sorbets': 'scat_fruits',
                    'Pâtisseries': 'scat_patisseries'
                }
            }
        }
        
       
        for cat_name, cat_data in categories_data.items():
            cat_id = cat_data['id']
            db.collection('categories').document(cat_id).set({
                'nomCat': cat_name
            })
            self.stdout.write(f"Catégorie créée: {cat_name}")
            
            
            for sous_cat_name, sous_cat_id in cat_data['sous_categories'].items():
                db.collection('sous_categories').document(sous_cat_id).set({
                    'nomSousCat': sous_cat_name,
                    'idCat': cat_id  
                })
                self.stdout.write(f"  Sous-catégorie créée: {sous_cat_name}")
        
        
        csv_data = """id_article,nom_article,catégorie,sous_catégorie,prix,description,ingrédients

101,Soupe à l'Oignon,Entrées,Soupes et Potages,7.50,"Soupe traditionnelle aux oignons caramélisés, gratinée au fromage comté","Oignons, bouillon de bœuf, comté, pain baguette"
102,Soupe de Potiron,Entrées,Soupes et Potages,7.00,"Velouté de potiron avec une touche de crème fraîche","Potiron, crème fraîche, noix de muscade"
103,Soupe de Poisson,Entrées,Soupes et Potages,10.00,"Soupe méditerranéenne aux poissons et rouille","Poissons, tomates, safran, rouille"

111,Salade Niçoise,Entrées,Salades et Crudités,9.00,"Salade méditerranéenne avec thon, olives, œufs, et haricots verts","Thon, olives noires, œufs, tomates, vinaigrette"
112,Salade de Chèvre Chaud,Entrées,Salades et Crudités,10.50,"Salade verte avec fromage de chèvre grillé sur toast","Chèvre, salade, noix, vinaigrette"
113,Salade César,Entrées,Salades et Crudités,11.00,"Salade romaine, croûtons, parmesan et sauce césar","Poulet, parmesan, croûtons, sauce césar"

121,Quiche Lorraine,Entrées,Spécialités Chaudes,8.50,"Tarte salée avec lardons, œufs, et crème fraîche","Lardons, œufs, crème, pâte brisée"
122,Feuilleté aux Champignons,Entrées,Spécialités Chaudes,9.00,"Feuilleté croustillant garni de champignons à la crème","Champignons, crème, pâte feuilletée"
123,Bruschetta Tomate-Mozzarella,Entrées,Spécialités Chaudes,8.50,"Pain grillé garni de tomates fraîches et mozzarella","Tomates, mozzarella, basilic, huile d'olive"

131,Carpaccio de Bœuf,Entrées,Spécialités Froides,14.00,"Tranches fines de bœuf marinées à l'huile d'olive et parmesan","Bœuf, parmesan, roquette, huile d'olive"
132,Rillettes de Thon,Entrées,Spécialités Froides,9.50,"Rillettes maison à base de thon et crème fraîche","Thon, crème fraîche, citron, ciboulette"
133,Tartare de Saumon,Entrées,Spécialités Froides,12.00,"Saumon frais coupé au couteau, citron, aneth, et capres","Saumon, aneth, citron, capres, toast"
134,Terrine de Campagne,Entrées,Spécialités Froides,8.00,"Terrine de porc et foie de volaille, cornichons, et pain de seigle","Porc, foie de volaille, épices"
135,Oeufs Mimosa,Entrées,Spécialités Froides,7.50,"Oeufs durs garnis de mayonnaise et jaune d'oeuf","Oeufs, mayonnaise, ciboulette"
136,Avocat Crevettes,Entrées,Spécialités Froides,12.50,"Demi-avocat garni de crevettes et sauce cocktail","Avocat, crevettes, sauce cocktail, citron"

201,Burger Bistrot,Plats,Sandwichs et Burgers,15.00,"Pain brioché, steak haché charolais, oignons confits, roquefort","Bœuf, roquefort, oignons, salade"
202,Croque-Monsieur,Plats,Sandwichs et Burgers,10.00,"Classique jambon et fromage gratiné","Jambon, emmental, pain de mie, béchamel"
203,Panini Poulet-Ratatouille,Plats,Sandwichs et Burgers,12.50,"Poulet grillé, ratatouille maison, et fromage de chèvre","Poulet, courgettes, aubergines, tomates"
204,Burger Végétarien,Plats,Sandwichs et Burgers,13.50,"Steak de légumes, avocat, et sauce yaourt","Légumes, avocat, yaourt, pain brioché"
205,Baguette Jambon-Beurre,Plats,Sandwichs et Burgers,8.00,"Baguette traditionnelle avec jambon et beurre","Jambon, beurre, baguette"
206,Burger BBQ,Plats,Sandwichs et Burgers,16.00,"Steak haché, sauce barbecue, oignons frits","Bœuf, sauce BBQ, oignons, cheddar"
207,Panini Saumon-Avocat,Plats,Sandwichs et Burgers,14.00,"Saumon fumé, avocat, et fromage frais","Saumon, avocat, fromage frais, pain panini"
208,Club Sandwich,Plats,Sandwichs et Burgers,12.00,"Poulet, bacon, laitue, tomate, et mayonnaise","Poulet, bacon, tomate, pain de mie"
209,Wrap Poulet-Crudités,Plats,Sandwichs et Burgers,11.50,"Poulet grillé, crudités, et sauce fromagère","Poulet, crudités, tortilla, sauce"

211,Coq au Vin,Plats,Cuisine Traditionnelle,16.00,"Cuisse de poulet mijotée au vin rouge (sans alcool), champignons","Poulet, carottes, oignons, bouillon"
212,Boeuf Bourguignon,Plats,Cuisine Traditionnelle,17.50,"Bœuf mijoté aux carottes et oignons, sauce riche","Bœuf, lardons, champignons, bouillon"
213,Ratatouille Provençale,Plats,Cuisine Traditionnelle,13.00,"Légumes du soleil rôtis au thym et à l'huile d'olive","Aubergines, courgettes, poivrons, tomates"
214,Quiche aux Poireaux,Plats,Cuisine Traditionnelle,11.00,"Tarte aux poireaux et fromage de chèvre","Poireaux, chèvre, œufs, crème"
215,Pot-au-Feu,Plats,Cuisine Traditionnelle,17.00,"Bœuf et légumes mijotés, bouillon parfumé","Bœuf, carottes, poireaux, navets"
216,Cassoulet,Plats,Cuisine Traditionnelle,16.50,"Haricots blancs, saucisse, et confit de canard","Haricots, saucisse, canard, tomates"

221,Daurade Grillée,Plats,Poissons et Fruits de Mer,18.00,"Filet de daurade, légumes grillés, et sauce vierge","Daurade, citron, courgettes, tomates cerises"
222,Saumon en Papillote,Plats,Poissons et Fruits de Mer,19.50,"Saumon cuit en papillote avec légumes","Saumon, courgettes, citron, aneth"

231,Blanquette de Veau,Plats,Viandes,19.00,"Veau mijoté à la crème et aux champignons","Veau, champignons, crème, carottes"
232,Confit de Canard,Plats,Viandes,18.50,"Cuisse de canard confite, pommes de terre sautées","Canard, pommes de terre, ail"
233,Lapin à la Moutarde,Plats,Viandes,16.50,"Lapin mijoté à la moutarde à l'ancienne","Lapin, moutarde, crème, échalotes"
234,Andouillette Grillée,Plats,Viandes,15.00,"Andouillette grillée, sauce moutarde","Andouillette, moutarde, pommes de terre"
235,Filet Mignon,Plats,Viandes,20.00,"Filet mignon de porc, sauce aux champignons","Porc, champignons, crème, échalotes"
236,Poulet Rôti,Plats,Viandes,15.50,"Poulet rôti avec jus de cuisson","Poulet, thym, ail, jus de cuisson"
237,Gigot d'Agneau,Plats,Viandes,22.00,"Gigot d'agneau rôti, flageolets","Agneau, flageolets, romarin"

241,Gratin de Légumes,Plats,Végétarien,12.00,"Courgettes, aubergines, et tomates gratinées au fromage","Légumes de saison, béchamel, emmental"
242,Galette de Lentilles,Plats,Végétarien,11.50,"Galette de lentilles corail, sauce yaourt-citron","Lentilles, carottes, oignons, épices"
243,Risotto aux Champignons,Plats,Végétarien,14.00,"Risotto crémeux aux champignons sauvages","Riz, champignons, parmesan, crème"
244,Tarte aux Legumes,Plats,Végétarien,12.50,"Tarte aux légumes de saison et fromage de chèvre","Légumes, chèvre, pâte brisée"
245,Falafel,Plats,Végétarien,10.50,"Boulettes de pois chiches, sauce tahini","Pois chiches, tahini, persil"
246,Lasagnes Végétariennes,Plats,Végétarien,13.50,"Lasagnes aux légumes et béchamel","Courgettes, aubergines, tomates, béchamel"
247,Curry de Légumes,Plats,Végétarien,12.00,"Curry doux aux légumes et lait de coco","Légumes, lait de coco, curry"
248,Pâtes aux Artichauts,Plats,Végétarien,11.50,"Pâtes fraîches aux artichauts et parmesan","Pâtes, artichauts, parmesan, crème"
249,Soupe de Lentilles,Plats,Végétarien,9.00,"Soupe épicée aux lentilles et légumes","Lentilles, carottes, oignons, épices"

301,Frites Maison,Accompagnements,Féculents,5.00,"Coupées à la main, sel de Guérande","Pommes de terre, huile d'arachide"
302,Gratin Dauphinois,Accompagnements,Féculents,6.50,"Pommes de terre, crème fraîche, et noix de muscade","Pommes de terre, crème, muscade"
303,Quinoa aux Herbes,Accompagnements,Féculents,5.00,"Quinoa, persil, coriandre, et tomates séchées","Quinoa, persil, coriandre, tomates"
304,Riz Basmati,Accompagnements,Féculents,4.00,"Riz basmati parfumé au beurre","Riz, beurre"
305,Pommes de Terre Sautées,Accompagnements,Féculents,5.50,"Pommes de terre sautées à l'ail et au persil","Pommes de terre, ail, persil"
306,Polenta,Accompagnements,Féculents,5.00,"Polenta crémeuse au parmesan","Polenta, parmesan, crème"

311,Petits Pois Carottes,Accompagnements,Légumes,4.50,"Petits pois et carottes à la française","Petits pois, carottes, oignons"
312,Légumes Rôtis,Accompagnements,Légumes,5.50,"Courgettes, carottes, et poivrons rôtis à l'huile d'olive","Courgettes, carottes, poivrons, huile d'olive"
313,Purée de Céleri-Rave,Accompagnements,Légumes,4.50,"Purée onctueuse au céleri-rave et crème fraîche","Céleri-rave, crème, beurre"
314,Haricots Verts,Accompagnements,Légumes,4.50,"Haricots verts à l'ail","Haricots verts, ail, beurre"

401,Café Allongé,Boissons,Boissons Chaudes,3.00,"Café filtre servi dans une grande tasse","Café arabica"
402,Thé à la Menthe Fraîche,Boissons,Boissons Chaudes,4.00,"Thé vert à la menthe fraîche et miel","Thé vert, menthe, miel"
403,Chocolat Viennois,Boissons,Boissons Chaudes,5.50,"Chocolat chaud épais avec chantilly et copeaux de chocolat","Chocolat noir, crème, sucre"
404,Infusion Verveine-Citron,Boissons,Boissons Chaudes,4.00,"Verveine et zeste de citron bio","Verveine, citron"
405,Café Noisette,Boissons,Boissons Chaudes,3.50,"Expresso avec une touche de lait mousseux","Café, lait"
406,Cappuccino,Boissons,Boissons Chaudes,4.50,"Expresso, lait mousseux, et cacao","Café, lait, cacao"
407,Thé Noir,Boissons,Boissons Chaudes,3.50,"Thé noir de Ceylan","Thé noir"
408,Latte Macchiato,Boissons,Boissons Chaudes,5.00,"Lait mousseux avec un trait d'expresso","Lait, café"
409,Chocolat à l'Orange,Boissons,Boissons Chaudes,5.50,"Chocolat chaud parfumé à l'orange","Chocolat, orange, crème"

411,Jus d'Orange Pressé,Boissons,Boissons Froides,5.00,"Pressé quotidiennement","Oranges fraîches"
412,Limonade Maison,Boissons,Boissons Froides,4.50,"Citron, sucre de canne, et eau gazeuse","Citron, sucre, eau"
413,Eau Infusée (Citron/Gingembre),Boissons,Boissons Froides,3.50,"Eau fraîche infusée au citron et gingembre","Citron, gingembre, eau"
414,Smoothie Tropical,Boissons,Boissons Froides,6.00,"Mangue, ananas, et banane mixés avec yaourt nature","Mangue, ananas, banane, yaourt"
415,Jus de Pomme,Boissons,Boissons Froides,4.50,"Jus de pomme pressé à froid","Pommes"
416,Coca-Cola,Boissons,Boissons Froides,3.50,"Soda classique","Eau gazéifiée, sucre, arômes"
417,Perrier,Boissons,Boissons Froides,3.00,"Eau minérale gazeuse","Eau minérale"
418,Ice Tea,Boissons,Boissons Froides,4.00,"Thé glacé à la pêche","Thé, pêche, sucre"
419,Jus de Carotte,Boissons,Boissons Froides,5.00,"Jus de carotte frais","Carottes"

501,Crème Brûlée,Desserts,Crèmes et Mousses,6.50,"Crème vanille caramélisée à la torche","Crème fraîche, vanille, sucre, œufs"
502,Tiramisu,Desserts,Crèmes et Mousses,6.50,"Dessert italien au café et mascarpone","Mascarpone, café, biscuits"
503,Mousse au Chocolat Noir,Desserts,Crèmes et Mousses,6.00,"Mousse 70% cacao, chantilly légère","Chocolat noir, œufs, crème"
504,Île Flottante,Desserts,Crèmes et Mousses,6.50,"Meringue légère sur crème anglaise vanillée","Œufs, lait, vanille"

511,Salade de Fruits Frais,Desserts,Fruits et Sorbets,5.50,"Fruits de saison coupés au couteau (melon, fraises, kiwi)","Melon, fraises, kiwi"
512,Sorbet Citron/Framboise,Desserts,Fruits et Sorbets,5.00,"Sorbet artisanal au choix","Citron ou framboise, eau, sucre"
513,Profiteroles,Desserts,Pâtisseries,7.50,"Choux garnis de glace vanille et sauce chocolat","Choux, glace, chocolat"
514,Fondant au Chocolat,Desserts,Pâtisseries,7.00,"Gâteau moelleux avec cœur coulant","Chocolat, beurre, œufs"
515,Tarte Tatin,Desserts,Pâtisseries,7.00,"Tarte renversée aux pommes caramélisées","Pommes, sucre, pâte feuilletée"
516,Clafoutis aux Cerises,Desserts,Pâtisseries,6.00,"Clafoutis traditionnel aux cerises","Cerises, lait, œufs, farine"
"""
        
        
        sous_cat_map = {}
        for cat_data in categories_data.values():
            for sous_cat_name, sous_cat_id in cat_data['sous_categories'].items():
                sous_cat_map[sous_cat_name] = sous_cat_id
        
       
        count = 0
        
       
        lines = csv_data.strip().split('\n')
        header = lines[0].split(',')
        
        
        current_line = 2
        
        while current_line < len(lines):
            line = lines[current_line].strip()
            current_line += 1
            
           
            if not line:
                continue
                
            
            parts = []
            current_part = ''
            in_quotes = False
            
            for char in line:
                if char == '"':
                    in_quotes = not in_quotes
                elif char == ',' and not in_quotes:
                    parts.append(current_part)
                    current_part = ''
                else:
                    current_part += char
            
           
            parts.append(current_part)
            
            
            if len(parts) < 7:
                self.stdout.write(self.style.WARNING(f"Ligne ignorée (format incorrect): {line}"))
                continue
                
            
            row = {
                'id_article': parts[0],
                'nom_article': parts[1],
                'catégorie': parts[2],
                'sous_catégorie': parts[3],
                'prix': parts[4],
                'description': parts[5],
                'ingrédients': parts[6]
            }
            
            
            cat_id = categories_data.get(row['catégorie'], {}).get('id')
            sous_cat_id = sous_cat_map.get(row['sous_catégorie'])
            
            if not cat_id or not sous_cat_id:
                self.stdout.write(self.style.WARNING(
                    f"Plat ignoré (catégorie ou sous-catégorie non trouvée): {row['nom_article']}"
                ))
                continue
            
            
            ingredients_list = [ing.strip() for ing in row['ingrédients'].replace('"', '').split(',')]
            
           
            plat_id = f"plat_{row['id_article']}"
            
           
            try:
                db.collection('plats').document(plat_id).set({
                    'nom': row['nom_article'],
                    'estimation': 15, 
                    'note': 4.0,      
                    'description': row['description'].replace('"', ''),
                    'ingrédients': ingredients_list,
                    'quantité': 100,  
                    'prix': float(row['prix']),
                    'idCat': cat_id,
                    'idSousCat': sous_cat_id
                })
                
                count += 1
                if count % 10 == 0:
                    self.stdout.write(f"Importation en cours... {count} plats importés")
                    
            except Exception as e:
                self.stdout.write(self.style.ERROR(
                    f"Erreur lors de l'importation du plat {row['nom_article']}: {str(e)}"
                ))
        
        self.stdout.write(self.style.SUCCESS(f"Importation terminée! {count} plats importés avec succès."))