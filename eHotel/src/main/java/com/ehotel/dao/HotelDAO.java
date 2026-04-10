package com.ehotel.dao;

import com.ehotel.config.DatabaseConfig;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class HotelDAO {
    public List<String> getAllHotels() {
        List<String> hotels = new ArrayList<>();
        String sql = "SELECT hotel_id, nom FROM hotel ORDER BY nom";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                hotels.add(rs.getInt("hotel_id") + ": " + rs.getString("nom"));
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la récupération des hôtels", e);
        }

        return hotels;
    }

    public List<String> getAllChains() {
        List<String> chains = new ArrayList<>();
        String sql = "SELECT chaine_id, nom FROM chaine_hotel ORDER BY nom";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                chains.add(rs.getInt("chaine_id") + ": " + rs.getString("nom"));
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la récupération des chaînes", e);
        }

        return chains;
    }

    public List<String> getAllZones() {
        List<String> zones = new ArrayList<>();
        String sql = "SELECT DISTINCT zone FROM hotel ORDER BY zone";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                zones.add(rs.getString("zone"));
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la récupération des zones", e);
        }

        return zones;
    }
}