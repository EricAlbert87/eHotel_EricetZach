package com.ehotel.dao;

import com.ehotel.config.DatabaseConfig;
import com.ehotel.model.RoomSearchResult;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class RoomDAO {
    public List<RoomSearchResult> searchRooms(String zone, int capacite, double prixMax, double superficieMin, String chaine, int categorie, String dateDebut, String dateFin, int nombreChambres) {
        List<RoomSearchResult> rooms = new ArrayList<>();

        String sql = """
                SELECT c.chambre_id, h.nom AS hotel, h.zone, c.numero, c.prix, c.capacite, c.superficie
                FROM chambre c
                JOIN hotel h ON h.hotel_id = c.hotel_id
                JOIN chaine_hotel ch ON ch.chaine_id = h.chaine_id
                WHERE c.statut = 'disponible'
                  AND (? = '' OR h.zone = ?)
                  AND c.capacite >= ?
                  AND c.prix <= ?
                  AND c.superficie >= ?
                  AND (? = '' OR ch.nom = ?)
                  AND (? = 0 OR h.categorie = ?)
                  AND (? = '' OR ? = '' OR NOT EXISTS (
                      SELECT 1 FROM reservation r
                      WHERE r.chambre_id = c.chambre_id
                        AND r.statut IN ('active', 'convertie')
                        AND r.date_debut < ?
                        AND r.date_fin > ?
                  ))
                ORDER BY h.zone, c.prix
                LIMIT ?
                """;

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, zone == null ? "" : zone);
            ps.setString(2, zone == null ? "" : zone);
            ps.setInt(3, capacite);
            ps.setDouble(4, prixMax);
            ps.setDouble(5, superficieMin);
            ps.setString(6, chaine == null ? "" : chaine);
            ps.setString(7, chaine == null ? "" : chaine);
            ps.setInt(8, categorie);
            ps.setInt(9, categorie);
            ps.setString(10, dateDebut == null ? "" : dateDebut);
            ps.setString(11, dateFin == null ? "" : dateFin);
            if (!dateDebut.isEmpty() && !dateFin.isEmpty()) {
                ps.setDate(12, java.sql.Date.valueOf(dateFin));
                ps.setDate(13, java.sql.Date.valueOf(dateDebut));
            } else {
                ps.setDate(12, java.sql.Date.valueOf("9999-12-31"));
                ps.setDate(13, java.sql.Date.valueOf("0001-01-01"));
            }
            ps.setInt(14, nombreChambres);

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

    public List<String> getAllRooms() {
        List<String> rooms = new ArrayList<>();
        String sql = "SELECT chambre_id, numero FROM chambre ORDER BY chambre_id";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                rooms.add(rs.getInt("chambre_id") + ": " + rs.getString("numero"));
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la récupération des chambres", e);
        }

        return rooms;
    }
}