package com.ehotel.service;

import com.ehotel.dao.ClientDAO;
import com.ehotel.dao.EmployeeDAO;
import com.ehotel.dao.HotelDAO;
import com.ehotel.dao.LocationDAO;
import com.ehotel.dao.ReservationDAO;
import com.ehotel.dao.RoomDAO;
import com.ehotel.model.BookingRequest;
import com.ehotel.model.RoomSearchResult;

import java.util.List;

public class HotelService {
    private final RoomDAO roomDAO = new RoomDAO();
    private final ReservationDAO reservationDAO = new ReservationDAO();
    private final ClientDAO clientDAO = new ClientDAO();
    private final EmployeeDAO employeeDAO = new EmployeeDAO();
    private final HotelDAO hotelDAO = new HotelDAO();
    private final LocationDAO locationDAO = new LocationDAO();

    public List<RoomSearchResult> searchRooms(String zone, int capacite, double prixMax, double superficieMin, String chaine, int categorie, String dateDebut, String dateFin, int nombreChambres) {
        return roomDAO.searchRooms(zone, capacite, prixMax, superficieMin, chaine, categorie, dateDebut, dateFin, nombreChambres);
    }

    public void reserveRoom(int clientId, int chambreId, String dateDebut, String dateFin) {
        reservationDAO.createReservation(new BookingRequest(clientId, chambreId, dateDebut, dateFin));
    }

    public void rentRoomDirectly(int clientId, int chambreId, String dateDebut, String dateFin, int employeId) {
        reservationDAO.createDirectRental(new BookingRequest(clientId, chambreId, dateDebut, dateFin), employeId);
    }

    public List<String> getAllClients() {
        return clientDAO.getAllClients();
    }

    public List<String> getAllEmployees() {
        return employeeDAO.getAllEmployees();
    }

    public List<String> getAllHotels() {
        return hotelDAO.getAllHotels();
    }

    public List<String> getAllRooms() {
        return roomDAO.getAllRooms();
    }

    public List<String> getAllReservations() {
        return reservationDAO.getAllReservations();
    }

    public List<String> getAllLocations() {
        return locationDAO.getAllLocations();
    }

    public void archiveReservation(int id) {
        reservationDAO.archiveReservation(id);
    }

    public void archiveLocation(int id) {
        locationDAO.archiveLocation(id);
    }

    public void convertReservationToLocation(int reservationId, int employeId) {
        reservationDAO.convertReservationToLocation(reservationId, employeId);
    }
}