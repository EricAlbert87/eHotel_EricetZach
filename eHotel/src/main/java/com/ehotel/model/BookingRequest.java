package com.ehotel.model;

public class BookingRequest {
    private final int clientId;
    private final int chambreId;
    private final String dateDebut;
    private final String dateFin;

    public BookingRequest(int clientId, int chambreId, String dateDebut, String dateFin) {
        this.clientId = clientId;
        this.chambreId = chambreId;
        this.dateDebut = dateDebut;
        this.dateFin = dateFin;
    }

    public int getClientId() { return clientId; }
    public int getChambreId() { return chambreId; }
    public String getDateDebut() { return dateDebut; }
    public String getDateFin() { return dateFin; }
}