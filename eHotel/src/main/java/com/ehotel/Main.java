package com.ehotel;

import com.ehotel.config.DatabaseConfig;
import com.ehotel.model.RoomSearchResult;
import com.ehotel.service.HotelService;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Main {
    private static final HotelService service = new HotelService();

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(DatabaseConfig.getServerPort()), 0);

        server.createContext("/", exchange -> serveStatic(exchange, "/static/index.html", "text/html; charset=utf-8"));
        server.createContext("/app.css", exchange -> serveStatic(exchange, "/static/app.css", "text/css; charset=utf-8"));
        server.createContext("/app.js", exchange -> serveStatic(exchange, "/static/app.js", "application/javascript; charset=utf-8"));

        server.createContext("/api/rooms", exchange -> {
            try {
                Map<String, String> query = parseQuery(exchange.getRequestURI().getRawQuery());
                String zone = query.getOrDefault("zone", "");
                int capacite = Integer.parseInt(query.getOrDefault("capacite", "1"));
                double prix = Double.parseDouble(query.getOrDefault("prix", "9999"));
                double superficie = Double.parseDouble(query.getOrDefault("superficie", "0"));
                String chaine = query.getOrDefault("chaine", "");
                int categorie = Integer.parseInt(query.getOrDefault("categorie", "0"));
                String dateDebut = query.getOrDefault("dateDebut", "");
                String dateFin = query.getOrDefault("dateFin", "");
                int nombreChambres = Integer.parseInt(query.getOrDefault("nombreChambres", "10"));

                List<RoomSearchResult> rooms = service.searchRooms(zone, capacite, prix, superficie, chaine, categorie, dateDebut, dateFin, nombreChambres);

                StringBuilder json = new StringBuilder("[");
                for (int i = 0; i < rooms.size(); i++) {
                    RoomSearchResult r = rooms.get(i);
                    if (i > 0) json.append(",");
                    json.append(String.format(
                            "{\"chambreId\":%d,\"hotel\":\"%s\",\"zone\":\"%s\",\"numero\":\"%s\",\"prix\":%.2f,\"capacite\":%d,\"superficie\":%.2f}",
                            r.getChambreId(),
                            escape(r.getHotel()),
                            escape(r.getZone()),
                            escape(r.getNumero()),
                            r.getPrix(),
                            r.getCapacite(),
                            r.getSuperficie()
                    ));
                }
                json.append("]");

                sendResponse(exchange, 200, json.toString(), "application/json; charset=utf-8");
            } catch (Exception e) {
                sendResponse(exchange, 500, "{\"error\":\"" + escape(e.getMessage()) + "\"}", "application/json; charset=utf-8");
            }
        });

        server.createContext("/api/chains", exchange -> {
            try {
                List<String> chains = service.getAllChains();
                String json = "[" + String.join(",", chains.stream().map(c -> "\"" + escape(c) + "\"").toList()) + "]";
                sendResponse(exchange, 200, json, "application/json; charset=utf-8");
            } catch (Exception e) {
                sendResponse(exchange, 500, "{\"error\":\"" + escape(e.getMessage()) + "\"}", "application/json; charset=utf-8");
            }
        });

        server.createContext("/api/zones", exchange -> {
            try {
                List<String> zones = service.getAllZones();
                String json = "[" + String.join(",", zones.stream().map(z -> "\"" + escape(z) + "\"").toList()) + "]";
                sendResponse(exchange, 200, json, "application/json; charset=utf-8");
            } catch (Exception e) {
                sendResponse(exchange, 500, "{\"error\":\"" + escape(e.getMessage()) + "\"}", "application/json; charset=utf-8");
            }
        });

        server.createContext("/api/employees", exchange -> {
            try {
                List<String> employees = service.getAllEmployees();
                String json = "[" + String.join(",", employees.stream().map(e -> "\"" + escape(e) + "\"").toList()) + "]";
                sendResponse(exchange, 200, json, "application/json; charset=utf-8");
            } catch (Exception e) {
                sendResponse(exchange, 500, "{\"error\":\"" + escape(e.getMessage()) + "\"}", "application/json; charset=utf-8");
            }
        });

        server.createContext("/api/hotels", exchange -> {
            try {
                List<String> hotels = service.getAllHotels();
                String json = "[" + String.join(",", hotels.stream().map(h -> "\"" + escape(h) + "\"").toList()) + "]";
                sendResponse(exchange, 200, json, "application/json; charset=utf-8");
            } catch (Exception e) {
                sendResponse(exchange, 500, "{\"error\":\"" + escape(e.getMessage()) + "\"}", "application/json; charset=utf-8");
            }
        });

        server.createContext("/api/allrooms", exchange -> {
            try {
                List<String> rooms = service.getAllRooms();
                String json = "[" + String.join(",", rooms.stream().map(r -> "\"" + escape(r) + "\"").toList()) + "]";
                sendResponse(exchange, 200, json, "application/json; charset=utf-8");
            } catch (Exception e) {
                sendResponse(exchange, 500, "{\"error\":\"" + escape(e.getMessage()) + "\"}", "application/json; charset=utf-8");
            }
        });

        server.createContext("/api/reservations", exchange -> {
            if ("GET".equalsIgnoreCase(exchange.getRequestMethod())) {
                try {
                    List<String> reservations = service.getAllReservations();
                    String json = "[" + String.join(",", reservations.stream().map(r -> "\"" + escape(r) + "\"").toList()) + "]";
                    sendResponse(exchange, 200, json, "application/json; charset=utf-8");
                } catch (Exception e) {
                    sendResponse(exchange, 500, "{\"error\":\"" + escape(e.getMessage()) + "\"}", "application/json; charset=utf-8");
                }
            } else if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                try {
                    Map<String, String> body = parseForm(exchange);
                    service.reserveRoom(
                            Integer.parseInt(body.get("clientId")),
                            Integer.parseInt(body.get("chambreId")),
                            body.get("dateDebut"),
                            body.get("dateFin")
                    );
                    sendResponse(exchange, 200, "Réservation créée avec succès.", "text/plain; charset=utf-8");
                } catch (Exception e) {
                    sendResponse(exchange, 500, "Erreur: " + e.getMessage(), "text/plain; charset=utf-8");
                }
            } else {
                sendResponse(exchange, 405, "Méthode non permise", "text/plain; charset=utf-8");
            }
        });

        server.createContext("/api/locations", exchange -> {
            if ("GET".equalsIgnoreCase(exchange.getRequestMethod())) {
                try {
                    List<String> locations = service.getAllLocations();
                    String json = "[" + String.join(",", locations.stream().map(r -> "\"" + escape(r) + "\"").toList()) + "]";
                    sendResponse(exchange, 200, json, "application/json; charset=utf-8");
                } catch (Exception e) {
                    sendResponse(exchange, 500, "{\"error\":\"" + escape(e.getMessage()) + "\"}", "application/json; charset=utf-8");
                }
            } else if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                try {
                    Map<String, String> body = parseForm(exchange);
                    service.rentRoomDirectly(
                            Integer.parseInt(body.get("clientId")),
                            Integer.parseInt(body.get("chambreId")),
                            body.get("dateDebut"),
                            body.get("dateFin"),
                            Integer.parseInt(body.get("employeId"))
                    );
                    sendResponse(exchange, 200, "Location créée avec succès.", "text/plain; charset=utf-8");
                } catch (Exception e) {
                    sendResponse(exchange, 500, "Erreur: " + e.getMessage(), "text/plain; charset=utf-8");
                }
            } else {
                sendResponse(exchange, 405, "Méthode non permise", "text/plain; charset=utf-8");
            }
        });

        server.createContext("/api/convert", exchange -> {
            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendResponse(exchange, 405, "Méthode non permise", "text/plain; charset=utf-8");
                return;
            }

            try {
                Map<String, String> body = parseForm(exchange);
                int reservationId = Integer.parseInt(body.get("reservationId"));
                int employeId = Integer.parseInt(body.get("employeId"));
                service.convertReservationToLocation(reservationId, employeId);
                sendResponse(exchange, 200, "Conversion effectuée avec succès.", "text/plain; charset=utf-8");
            } catch (Exception e) {
                sendResponse(exchange, 500, "Erreur: " + e.getMessage(), "text/plain; charset=utf-8");
            }
        });

        server.createContext("/api/archive/reservation/", exchange -> {
            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendResponse(exchange, 405, "Méthode non permise", "text/plain; charset=utf-8");
                return;
            }

            String path = exchange.getRequestURI().getPath();
            String[] parts = path.split("/");
            if (parts.length != 5 || !parts[4].matches("\\d+")) {
                sendResponse(exchange, 400, "URL invalide", "text/plain; charset=utf-8");
                return;
            }

            try {
                int id = Integer.parseInt(parts[4]);
                service.archiveReservation(id);
                sendResponse(exchange, 200, "Réservation archivée.", "text/plain; charset=utf-8");
            } catch (Exception e) {
                sendResponse(exchange, 500, "Erreur: " + e.getMessage(), "text/plain; charset=utf-8");
            }
        });

        server.createContext("/api/archive/location/", exchange -> {
            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendResponse(exchange, 405, "Méthode non permise", "text/plain; charset=utf-8");
                return;
            }

            String path = exchange.getRequestURI().getPath();
            String[] parts = path.split("/");
            if (parts.length != 5 || !parts[4].matches("\\d+")) {
                sendResponse(exchange, 400, "URL invalide", "text/plain; charset=utf-8");
                return;
            }

            try {
                int id = Integer.parseInt(parts[4]);
                service.archiveLocation(id);
                sendResponse(exchange, 200, "Location archivée.", "text/plain; charset=utf-8");
            } catch (Exception e) {
                sendResponse(exchange, 500, "Erreur: " + e.getMessage(), "text/plain; charset=utf-8");
            }
        });

        server.start();
        System.out.println("eHotel démarré sur http://localhost:" + DatabaseConfig.getServerPort());
    }

    private static void serveStatic(HttpExchange exchange, String path, String contentType) throws IOException {
        try (InputStream input = Main.class.getResourceAsStream(path)) {
            if (input == null) {
                sendResponse(exchange, 404, "Fichier introuvable", "text/plain; charset=utf-8");
                return;
            }

            byte[] data = input.readAllBytes();
            exchange.getResponseHeaders().add("Content-Type", contentType);
            exchange.sendResponseHeaders(200, data.length);

            try (OutputStream os = exchange.getResponseBody()) {
                os.write(data);
            }
        }
    }

    private static Map<String, String> parseQuery(String query) {
        Map<String, String> map = new HashMap<>();
        if (query == null || query.isBlank()) return map;

        for (String pair : query.split("&")) {
            String[] parts = pair.split("=", 2);
            String key = URLDecoder.decode(parts[0], StandardCharsets.UTF_8);
            String value = parts.length > 1 ? URLDecoder.decode(parts[1], StandardCharsets.UTF_8) : "";
            map.put(key, value);
        }
        return map;
    }

    private static Map<String, String> parseForm(HttpExchange exchange) throws IOException {
        String body = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
        return parseQuery(body);
    }

    private static void sendResponse(HttpExchange exchange, int status, String body, String contentType) throws IOException {
        byte[] data = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().add("Content-Type", contentType);
        exchange.sendResponseHeaders(status, data.length);

        try (OutputStream os = exchange.getResponseBody()) {
            os.write(data);
        }
    }

    private static String escape(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}