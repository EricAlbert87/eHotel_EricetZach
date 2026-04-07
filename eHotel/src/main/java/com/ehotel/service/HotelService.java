package main.java.com.ehotel.service;

import main.java.com.ehotel.dao.ReservationDAO;
import main.java.com.ehotel.dao.RoomDAO;
import main.java.com.ehotel.model.BookingRequest;
import main.java.com.ehotel.model.RoomSearchResult;

import java.util.List;

public class HotelService {
    private final RoomDAO roomDAO = new RoomDAO();
    private final ReservationDAO reservationDAO = new ReservationDAO();

    public List<RoomSearchResult> searchRooms(String zone, int capacite, double prixMax, double superficieMin) {
        return roomDAO.searchRooms(zone, capacite, prixMax, superficieMin);
    }

    public void reserveRoom(int clientId, int chambreId, String dateDebut, String dateFin) {
        reservationDAO.createReservation(new BookingRequest(clientId, chambreId, dateDebut, dateFin));
    }

    public void rentRoomDirectly(int clientId, int chambreId, String dateDebut, String dateFin, int employeId) {
        reservationDAO.createDirectRental(new BookingRequest(clientId, chambreId, dateDebut, dateFin), employeId);
    }
}