package com.ehotel.dao;

import com.ehotel.config.DatabaseConfig;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class EmployeeDAO {
    public List<String> getAllEmployees() {
        List<String> employees = new ArrayList<>();
        String sql = "SELECT employe_id, nom_complet FROM employe ORDER BY nom_complet";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                employees.add(rs.getInt("employe_id") + ": " + rs.getString("nom_complet"));
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la récupération des employés", e);
        }

        return employees;
    }
}