package com.ehotel.dao;

import com.ehotel.config.DatabaseConfig;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class ClientDAO {
    public List<String> getAllClients() {
        List<String> clients = new ArrayList<>();
        String sql = "SELECT client_id, nom_complet FROM client ORDER BY nom_complet";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                clients.add(rs.getInt("client_id") + ": " + rs.getString("nom_complet"));
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la récupération des clients", e);
        }

        return clients;
    }
}