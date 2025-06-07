// src/main/java/com/church/cms/controller/AuthController.java
package com.church.cms.controller;

import com.church.cms.entity.Organization;
import com.church.cms.entity.Role;
import com.church.cms.entity.User;
import com.church.cms.service.UserService;
import com.church.cms.entity.UserRole;
import com.church.cms.payload.request.ForgotPasswordRequest;
import com.church.cms.payload.request.LoginRequest;
import com.church.cms.payload.request.RegisterRequest;
import com.church.cms.payload.request.ResetPasswordRequest;
import com.church.cms.payload.response.JwtResponse;
import com.church.cms.payload.response.MessageResponse;
import com.church.cms.repository.OrganizationRepository;
import com.church.cms.repository.RoleRepository;
import com.church.cms.repository.UserRepository;
import com.church.cms.repository.UserRoleRepository;
import com.church.cms.security.jwt.JwtUtils;
import com.church.cms.service.UserDetailsImpl;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import org.springframework.security.core.AuthenticationException;

// import java.util.HashSet;
import java.util.Optional;
// import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@CrossOrigin(origins = "*", maxAge = 3600) // CORS for development, configure properly in production
@RestController
@RequestMapping("/api/auth")
public class AuthController {

       private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

      @Autowired
    AuthenticationManager authenticationManager;

    @Autowired
    UserRepository userRepository;

    @Autowired
    OrganizationRepository organizationRepository;

    @Autowired
    RoleRepository roleRepository;

    @Autowired
    UserRoleRepository userRoleRepository;

    @Autowired
    PasswordEncoder encoder;

    @Autowired
    JwtUtils jwtUtils;

    @Autowired // <--- PASTIKAN ANOTASI INI ADA
    UserService userService; // <--- PASTIKAN DEKLARASI VARIABEL INI ADA


    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@Valid @RequestBody RegisterRequest registerRequest) {
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            return ResponseEntity
                    .badRequest()
                    .body(new MessageResponse("Error: Email is already in use!"));
        }

        // System.out.println(registerRequest.getEmail());

        // Check if organization exists, if not, create new one
        Optional<Organization> existingOrg = organizationRepository.findByName(registerRequest.getOrganizationName());
        final Organization organizationToUse;
        if (existingOrg.isPresent()) {
            organizationToUse = existingOrg.get();
        } else {
            Organization newOrg = new Organization(); // Buat objek baru
            newOrg.setName(registerRequest.getOrganizationName());
            newOrg.setEmail(registerRequest.getEmail());
            organizationToUse = organizationRepository.save(newOrg); 

           // Create a default 'Super Admin' role for the new organization
            Role superAdminRole = new Role();
            superAdminRole.setOrganization(organizationToUse); // Gunakan organizationToUse
            superAdminRole.setName("SUPER_ADMIN");
            superAdminRole.setDescription("System-defined Super Admin role for initial organization creator.");
            superAdminRole.setSystemRole(true);
            roleRepository.save(superAdminRole);
        }

      // Sekarang, gunakan organizationToUse di seluruh bagian kode selanjutnya
        User user = new User();
        user.setOrganization(organizationToUse); // Gunakan organizationToUse
        user.setEmail(registerRequest.getEmail());
        user.setUsername(registerRequest.getEmail());
        user.setPasswordHash(encoder.encode(registerRequest.getPassword()));
        user.setFirstName(registerRequest.getFirstName());
        user.setLastName(registerRequest.getLastName());
        user.setPhone(registerRequest.getPhone());
        user.setAvatarUrl(null);
        user.setEmailVerified(false);
        user.setActive(true);
        user.setRequire2fa(false);
        user.setLastLoginAt(null);
        // createdAt dan updatedAt akan diatur otomatis oleh @PrePersist atau default di entitas
        User savedUser = userRepository.save(user);

        // Assign 'Super Admin' role to the first user of the organization
        // For existing organizations, assume a default 'Member' or 'User' role, or require admin assignment.
        // For simplicity, for any new user registering without an existing org, they become Super Admin of their new org.
        Role defaultRole;
        if (!existingOrg.isPresent()) { // If new organization
            defaultRole = roleRepository.findByOrganizationAndName(organizationToUse, "SUPER_ADMIN") // Gunakan organizationToUse
                .orElseThrow(() -> new RuntimeException("Error: Super Admin Role not found for new organization."));
        } else {
            // For existing organizations, you might have a different registration flow,
            // perhaps requiring an existing admin to invite users, or default to a "MEMBER" role.
            // For now, let's assume if org exists, user needs to be manually assigned a role or default to 'MEMBER'
            defaultRole = roleRepository.findByOrganizationAndName(organizationToUse, "MEMBER") // Gunakan organizationToUse
                .orElseGet(() -> { // Create MEMBER role if it doesn't exist
                    Role memberRole = new Role();
                    memberRole.setOrganization(organizationToUse); // Gunakan organizationToUse di dalam lambda
                    memberRole.setName("MEMBER");
                    memberRole.setDescription("Default role for general members.");
                    return roleRepository.save(memberRole);
                });
        }

      UserRole userRole = new UserRole(null, savedUser, defaultRole, null);
        userRoleRepository.save(userRole);

        return ResponseEntity.ok(new MessageResponse("User registered successfully! Organization created if new."));
      }

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {

    logger.info("Raw password from request (DEBUG ONLY): {}", loginRequest.getPassword());

    Authentication authentication;
    try {
        authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));
        logger.info("Authentication successful for email: {}", loginRequest.getEmail());
    } catch (AuthenticationException e) {
        // Log tipe pengecualian dan full stack trace
        logger.error("Authentication failed for email: {}. Exception Type: {}", loginRequest.getEmail(), e.getClass().getName());
        logger.error("Stack trace:", e); // Ini akan mencetak full stack trace
        throw e; // Penting: lempar kembali pengecualian
    }

    SecurityContextHolder.getContext().setAuthentication(authentication);
    UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();

    String jwt = jwtUtils.generateJwtToken(userDetails);
    String refreshToken = jwtUtils.generateRefreshToken(userDetails);

    String roleName = userDetails.getAuthorities().stream()
                            .filter(a -> a.getAuthority().startsWith("ROLE_"))
                            .map(a -> a.getAuthority().replace("ROLE_", ""))
                            .findFirst()
                            .orElse("NONE");

    return ResponseEntity.ok(new JwtResponse(
        jwt,
        refreshToken,
        userDetails.getId(),
        userDetails.getEmail(),
        userDetails.getOrganizationId(),
        userDetails.getFirstName(),
        userDetails.getLastName(),
        roleName
    ));
}

    // You can add more endpoints here, e.g., refreshToken, logout, resetPassword, etc.
    // For refreshToken:
    @PostMapping("/refresh-token")
    public ResponseEntity<?> refreshToken(@RequestParam String refreshToken) {
        if (jwtUtils.validateJwtToken(refreshToken)) {
            String username = jwtUtils.getUserNameFromJwtToken(refreshToken);
            Long userId = jwtUtils.getUserIdFromJwtToken(refreshToken);
            Long organizationId = jwtUtils.getOrganizationIdFromJwtToken(refreshToken);

            // Re-generate access token
            String newAccessToken = jwtUtils.generateTokenFromUsername(username, userId, organizationId, jwtUtils.getJwtExpirationMs());
            return ResponseEntity.ok(new JwtResponse(newAccessToken, refreshToken, userId, username, organizationId, null, null, null)); // Populate other fields if needed
        }
        return ResponseEntity.badRequest().body(new MessageResponse("Invalid refresh token."));
    }

        // --- New Endpoints for Password Reset ---

    @PostMapping("/forgot-password")
    public ResponseEntity<MessageResponse> forgotPassword(@Valid @RequestBody ForgotPasswordRequest forgotPasswordRequest) {
        try {
            userService.initiatePasswordReset(forgotPasswordRequest);
            // Penting: Selalu kembalikan respon sukses bahkan jika email tidak ditemukan
            // untuk mencegah enumerasi pengguna.
            return ResponseEntity.ok(new MessageResponse("If your email is registered, a password reset link has been sent to your email address."));
        } catch (Exception e) {
            logger.error("Error initiating password reset for email {}: {}", forgotPasswordRequest.getEmail(), e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error processing password reset request. Please try again later."));
        }
    }

    @PostMapping("/reset-password")
    public ResponseEntity<MessageResponse> resetPassword(@Valid @RequestBody ResetPasswordRequest resetPasswordRequest) {
        try {
            userService.resetPassword(resetPasswordRequest);
            return ResponseEntity.ok(new MessageResponse("Password has been reset successfully!"));
        } catch (RuntimeException e) { // Tangkap custom exception jika Anda membuatnya
            logger.error("Error resetting password for token {}: {}", resetPasswordRequest.getToken(), e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new MessageResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("Internal server error during password reset for token {}: {}", resetPasswordRequest.getToken(), e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error resetting password. Please try again later."));
        }
    }
}