package com.petconnect.service;

import com.petconnect.model.Appointment;
import com.petconnect.repository.AppointmentRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final PetService petService;
    private final UserService userService;

    public AppointmentService(AppointmentRepository appointmentRepository, PetService petService, UserService userService) {
        this.appointmentRepository = appointmentRepository;
        this.petService = petService;
        this.userService = userService;
    }

    public List<Appointment> getAppointmentsByVetId(String vetId) {
        List<Appointment> appointments = appointmentRepository.findByVetId(vetId);
        return appointments.stream()
                .map(appointment -> {
                    appointment.setPet(petService.getPetById(appointment.getPetId()));
                    appointment.setOwner(userService.getUser(appointment.getOwnerId()).orElse(null));
                    return appointment;
                })
                .collect(Collectors.toList());
    }

    public Appointment createAppointment(Appointment appointment) {
        return appointmentRepository.save(appointment);
    }

    public Appointment updateAppointmentStatus(Long id, String status) {
        return appointmentRepository.findById(id)
                .map(existingAppointment -> {
                    existingAppointment.setStatus(status);
                    return appointmentRepository.save(existingAppointment);
                })
                .orElse(null);
    }
}
