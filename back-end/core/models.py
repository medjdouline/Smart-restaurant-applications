from django.db import models

class Client(models.Model):
    idC = models.AutoField(primary_key=True)
    username = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    motDePasse = models.CharField(max_length=128)
    isGuest = models.BooleanField(default=False)
    
    def __str__(self):
        return self.username


class Table(models.Model):
    ETAT_TABLE_CHOICES = [
        ('libre', 'Libre'),
        ('reservee', 'Réservée'),
        ('occupee', 'Occupée')
    ]
    
    idT = models.AutoField(primary_key=True)
    nbrPersonne = models.IntegerField()
    etatTable = models.CharField(max_length=20, choices=ETAT_TABLE_CHOICES)
    
    def __str__(self):
        return f"Table {self.idT} - {self.nbrPersonne} personnes"

class Reservation(models.Model):
    idRes = models.AutoField(primary_key=True)
    date = models.DateField()
    heure = models.TimeField()
    idT = models.ForeignKey(Table, on_delete=models.CASCADE)
    idC = models.ForeignKey(Client, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Réservation {self.idRes} - {self.date} {self.heure}"

class Fidelite(models.Model):
    idF = models.AutoField(primary_key=True)
    pointsFidélité = models.IntegerField(default=0)
    SeuilVIP = models.IntegerField(default=100)
    idC = models.OneToOneField(Client, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Fidélité de {self.idC.username}"

class Categorie(models.Model):
    idCat = models.AutoField(primary_key=True)
    nomCat = models.CharField(max_length=100)
    
    def __str__(self):
        return self.nomCat

class Plat(models.Model):
    idP = models.AutoField(primary_key=True)
    estimation = models.DecimalField(max_digits=10, decimal_places=2)
    note = models.DecimalField(max_digits=3, decimal_places=1, null=True, blank=True)
    description = models.TextField()
    ingrédients = models.JSONField(default=dict)
    quantité = models.IntegerField(default=1)
    idCat = models.ForeignKey(Categorie, on_delete=models.SET_NULL, null=True)
    
    def __str__(self):
        return f"Plat #{self.idP}"

class Menu(models.Model):
    idM = models.AutoField(primary_key=True)
    nomMenu = models.CharField(max_length=100)
    plats = models.ManyToManyField(Plat, through='Menu_Plat')
    
    def __str__(self):
        return self.nomMenu

class Menu_Plat(models.Model):
    idM = models.ForeignKey(Menu, on_delete=models.CASCADE)
    idP = models.ForeignKey(Plat, on_delete=models.CASCADE)
    
    class Meta:
        unique_together = ('idM', 'idP')
    
    def __str__(self):
        return f"{self.idM.nomMenu} - {self.idP}"

class Commande(models.Model):
    ETAT_CHOICES = [
        ('en_attente', 'En attente'),
        ('en_preparation', 'En préparation'),
        ('prete', 'Prête'),
        ('livree', 'Livrée')
    ]
    
    idCmd = models.AutoField(primary_key=True)
    montant = models.DecimalField(max_digits=10, decimal_places=2)
    dateCreation = models.DateTimeField(auto_now_add=True)
    etat = models.CharField(max_length=20, choices=ETAT_CHOICES)
    confirmation = models.BooleanField(default=False)
    idC = models.ForeignKey(Client, on_delete=models.CASCADE)
    plats = models.ManyToManyField(Plat, through='Commande_Plat')
    
    def __str__(self):
        return f"Commande #{self.idCmd} - {self.idC.username}"

class Commande_Plat(models.Model):
    idCmd = models.ForeignKey(Commande, on_delete=models.CASCADE)
    idP = models.ForeignKey(Plat, on_delete=models.CASCADE)
    quantité = models.IntegerField(default=1)
    
    class Meta:
        unique_together = ('idCmd', 'idP')
    
    def __str__(self):
        return f"Commande #{self.idCmd.idCmd} - Plat #{self.idP.idP} - {self.quantité}x"

class Recommandation(models.Model):
    idR = models.AutoField(primary_key=True)
    date_generation = models.DateTimeField(auto_now_add=True)
    idC = models.ForeignKey(Client, on_delete=models.CASCADE)
    plats = models.ManyToManyField(Plat, through='Recommandation_Plat')
    
    def __str__(self):
        return f"Recommandation #{self.idR} pour {self.idC.username}"

class Recommandation_Plat(models.Model):
    idR = models.ForeignKey(Recommandation, on_delete=models.CASCADE)
    idP = models.ForeignKey(Plat, on_delete=models.CASCADE)
    
    class Meta:
        unique_together = ('idR', 'idP')
    
    def __str__(self):
        return f"Recommandation #{self.idR.idR} - Plat #{self.idP.idP}"

class Ingredient(models.Model):
    idIng = models.AutoField(primary_key=True)
    nomIng = models.CharField(max_length=100)
    nbrMax = models.IntegerField()
    nbrMin = models.IntegerField()
    
    def __str__(self):
        return self.nomIng

class Stock(models.Model):
    idStock = models.AutoField(primary_key=True)
    capacitéS = models.IntegerField()
    SeuilAlerte = models.IntegerField()
    idIng = models.ForeignKey(Ingredient, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Stock de {self.idIng.nomIng}"

class MontantEncaisse(models.Model):
    idMontant = models.AutoField(primary_key=True)
    dateMontant = models.DateField()
    totalEncaissé = models.DecimalField(max_digits=10, decimal_places=2)
    
    def __str__(self):
        return f"Montant encaissé du {self.dateMontant}: {self.totalEncaissé}"

class Depenses(models.Model):
    idDep = models.AutoField(primary_key=True)
    dateDep = models.DateField()
    totaleDep = models.DecimalField(max_digits=10, decimal_places=2)
    
    def __str__(self):
        return f"Dépenses du {self.dateDep}: {self.totaleDep}"

class RapportFinancier(models.Model):
    idRapport = models.AutoField(primary_key=True)
    dateRapport = models.DateField()
    beneficeNet = models.DecimalField(max_digits=10, decimal_places=2)
    idMontant = models.ForeignKey(MontantEncaisse, on_delete=models.CASCADE)
    idDep = models.ForeignKey(Depenses, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Rapport financier du {self.dateRapport}"

class Employe(models.Model):
    ROLE_CHOICES = [
        ('CUISINIER', 'Cuisinier'),
        ('SERVEUR', 'Serveur'),
        ('MANAGER', 'Manager')
    ]
    
    idE = models.AutoField(primary_key=True)
    nomE = models.CharField(max_length=100)
    prénomE = models.CharField(max_length=100)
    usernameE = models.CharField(max_length=100, unique=True)
    adresseE = models.CharField(max_length=200)
    motDePasseE = models.CharField(max_length=128)
    rôle = models.CharField(max_length=20, choices=ROLE_CHOICES)
    
    def __str__(self):
        return f"{self.prénomE} {self.nomE} - {self.rôle}"

class Manager(models.Model):
    idE = models.OneToOneField(Employe, on_delete=models.CASCADE, primary_key=True)
    idRapport = models.ForeignKey(RapportFinancier, on_delete=models.SET_NULL, null=True)
    
    def __str__(self):
        return f"Manager: {self.idE.prénomE} {self.idE.nomE}"

class Cuisinier(models.Model):
    idE = models.OneToOneField(Employe, on_delete=models.CASCADE, primary_key=True)
    dateEmbauche = models.DateField()
    niveauExperience = models.CharField(max_length=50)
    
    def __str__(self):
        return f"Cuisinier: {self.idE.prénomE} {self.idE.nomE}"

class Cuisinier_Menu(models.Model):
    idE = models.ForeignKey(Cuisinier, on_delete=models.CASCADE)
    idM = models.ForeignKey(Menu, on_delete=models.CASCADE)
    datecreation = models.DateField()
    derniereMAJ = models.DateField()
    
    class Meta:
        unique_together = ('idE', 'idM')
    
    def __str__(self):
        return f"Menu {self.idM.nomMenu} créé par {self.idE.idE.prénomE} {self.idE.idE.nomE}"

class Serveur(models.Model):
    idE = models.OneToOneField(Employe, on_delete=models.CASCADE, primary_key=True)
    dateEmbauche = models.DateField()
    zoneAffectation = models.CharField(max_length=100)
    commandes = models.ManyToManyField(Commande, through='Serveur_Commande')
    
    def __str__(self):
        return f"Serveur: {self.idE.prénomE} {self.idE.nomE}"

class Serveur_Commande(models.Model):
    idE = models.ForeignKey(Serveur, on_delete=models.CASCADE)
    idCmd = models.ForeignKey(Commande, on_delete=models.CASCADE)
    
    class Meta:
        unique_together = ('idE', 'idCmd')
    
    def __str__(self):
        return f"Serveur {self.idE.idE.prénomE} {self.idE.idE.nomE} - Commande #{self.idCmd.idCmd}"