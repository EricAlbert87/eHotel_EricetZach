package com.ehotel.model;

public class RoomSearchResult {
    private final int chambreId;
    private final String hotel;
    private final String zone;
    private final String numero;
    private final double prix;
    private final int capacite;
    private final double superficie;

    public RoomSearchResult(int chambreId, String hotel, String zone, String numero, double prix, int capacite, double superficie) {
        this.chambreId = chambreId;
        this.hotel = hotel;
        this.zone = zone;
        this.numero = numero;
        this.prix = prix;
        this.capacite = capacite;
        this.superficie = superficie;
    }

    public int getChambreId() { return chambreId; }
    public String getHotel() { return hotel; }
    public String getZone() { return zone; }
    public String getNumero() { return numero; }
    public double getPrix() { return prix; }
    public int getCapacite() { return capacite; }
    public double getSuperficie() { return superficie; }
}