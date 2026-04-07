package com.ehotel.dao;

import com.ehotel.config.DatabaseConfig;
import com.ehotel.model.RoomSearchResult;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class RoomDAO {
    public List<RoomSearchResult> searchRooms(String zone, int capacite, double prixMax, double superficieMin) {
        List<RoomSearchResult> rooms = new ArrayList<>();

        String sql = """
                SELECT c.chambre_id, h.nom AS hotel, h.zone, c.numero, c.prix, c.capacite, c.superficie
                FROM chambre c
                JOIN hotel h ON h.hotel_id = c.hotel_id
                WHERE c.statut = 'disponible'
                  AND (? = '' OR h.zone = ?)
                  AND c.capacite >= ?
                  AND c.prix <= ?
                  AND c.superficie >= ?
                ORDER BY h.zone, c.prix
                """;

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, zone == null ? "" : zone);
            ps.setString(2, zone == null ? "" : zone);
            ps.setInt(3, capacite);
            ps.setDouble(4, prixMax);
            ps.setDouble(5, superficieMin);

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                rooms.add(new RoomSearchResult(
                        rs.getInt("chambre_id"),
                        rs.getString("hotel"),
                        rs.getString("zone"),
                        rs.getString("numero"),
                        rs.getDouble("prix"),
                        rs.getInt("capacite"),
                        rs.getDouble("superficie")
                ));
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la recherche des chambres", e);
        }

        return rooms;
    }
}