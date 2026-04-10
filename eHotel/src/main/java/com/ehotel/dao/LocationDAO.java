package com.ehotel.dao;

import com.ehotel.config.DatabaseConfig;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class LocationDAO {

    public List<String> getAllLocations() {
        List<String> locations = new ArrayList<>();
        String sql = "SELECT location_id, client_id, chambre_id, date_debut, date_fin FROM location WHERE statut = 'active' ORDER BY location_id";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                locations.add(rs.getInt("location_id") + ": Client " + rs.getInt("client_id") + ", Chambre " + rs.getInt("chambre_id") + ", " + rs.getDate("date_debut") + " to " + rs.getDate("date_fin"));
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la récupération des locations", e);
        }

        return locations;
    }

    public void archiveLocation(int id) {
        String sql = "UPDATE location SET statut = 'archivée' WHERE location_id = ?";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.executeUpdate();

        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de l'archivage de la location", e);
        }
    }
}