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
}