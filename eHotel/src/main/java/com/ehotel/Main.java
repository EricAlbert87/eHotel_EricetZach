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

                List<RoomSearchResult> rooms = service.searchRooms(zone, capacite, prix, superficie);

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

        server.createContext("/api/reservations", exchange -> {
            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendResponse(exchange, 405, "Méthode non permise", "text/plain; charset=utf-8");
                return;
            }

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
        });

        server.createContext("/api/locations", exchange -> {
            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendResponse(exchange, 405, "Méthode non permise", "text/plain; charset=utf-8");
                return;
            }

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