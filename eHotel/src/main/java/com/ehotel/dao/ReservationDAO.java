package com.ehotel.dao;

import com.ehotel.config.DatabaseConfig;
import com.ehotel.model.BookingRequest;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

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

    public List<String> getAllReservations() {
        List<String> reservations = new ArrayList<>();
        String sql = "SELECT reservation_id, client_id, chambre_id, date_debut, date_fin FROM reservation WHERE statut = 'active' ORDER BY reservation_id";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                reservations.add(rs.getInt("reservation_id") + ": Client " + rs.getInt("client_id") + ", Chambre " + rs.getInt("chambre_id") + ", " + rs.getDate("date_debut") + " to " + rs.getDate("date_fin"));
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la récupération des réservations", e);
        }

        return reservations;
    }

    public void convertReservationToLocation(int reservationId, int employeId) {
        // First, get reservation details
        String selectSql = "SELECT client_id, chambre_id, date_debut, date_fin FROM reservation WHERE reservation_id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement selectPs = conn.prepareStatement(selectSql)) {
            selectPs.setInt(1, reservationId);
            ResultSet rs = selectPs.executeQuery();
            if (rs.next()) {
                int clientId = rs.getInt("client_id");
                int chambreId = rs.getInt("chambre_id");
                String dateDebut = rs.getDate("date_debut").toString();
                String dateFin = rs.getDate("date_fin").toString();

                // Create location
                createDirectRental(new BookingRequest(clientId, chambreId, dateDebut, dateFin), employeId);
            } else {
                throw new RuntimeException("Réservation non trouvée");
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la conversion", e);
        }
    }
}