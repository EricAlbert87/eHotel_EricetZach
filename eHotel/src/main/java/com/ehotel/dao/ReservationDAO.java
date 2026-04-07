package main.java.com.ehotel.dao;

import main.java.com.ehotel.config.DatabaseConfig;
import main.java.com.ehotel.model.BookingRequest;

import java.sql.Connection;
import java.sql.PreparedStatement;

public class ReservationDAO {

    public void createReservation(BookingRequest request) {
        String sql = "INSERT INTO reservation (client_id, chambre_id, date_debut, date_fin) VALUES (?, ?, ?, ?)";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, request.getClientId());
            ps.setInt(2, request.getChambreId());
            ps.setDate(3, java.sql.Date.valueOf(request.getDateDebut()));
            ps.setDate(4, java.sql.Date.valueOf(request.getDateFin()));
            ps.executeUpdate();

        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la création de la réservation", e);
        }
    }

    public void createDirectRental(BookingRequest request, int employeId) {
        String sql = "INSERT INTO location (client_id, chambre_id, reservation_id, employe_id, date_debut, date_fin, type_location, statut) VALUES (?, ?, NULL, ?, ?, ?, 'directe', 'active')";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, request.getClientId());
            ps.setInt(2, request.getChambreId());
            ps.setInt(3, employeId);
            ps.setDate(4, java.sql.Date.valueOf(request.getDateDebut()));
            ps.setDate(5, java.sql.Date.valueOf(request.getDateFin()));
            ps.executeUpdate();

        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la création de la location", e);
        }
    }
}