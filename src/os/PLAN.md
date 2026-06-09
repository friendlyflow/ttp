# PLAN

##
- alle functies werken down de hierarchie
- functie loopt niet, pas bij functie call
- als er een nieuw object wordt gemaakt dan krijgt die een heap adres
- ordenen van de heap kan gaandeweg
- updates en schrijven van code volgen zelfde heap ordening proces

##
- struct {
    - id int32
    - children length int32
    - children int64*
    - content length int32
    - content char*
} NODE
- binary search op id's, of andere search, moet per depth zoeken
- nodes kunnen gesorteerd worden, tenzij voor security dat die random moeten zijn, os bepaald plaats in memory afhankelijk van grootte
- op 4 kilo byte normaal structure padding of data alignment, maar dat hoeft niet he