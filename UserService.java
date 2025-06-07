package com.church.cms.service;

import com.church.cms.entity.PasswordResetToken;
import com.church.cms.entity.User;
import com.church.cms.payload.request.ForgotPasswordRequest;
import com.church.cms.payload.request.ResetPasswordRequest;
import com.church.cms.repository.PasswordResetTokenRepository;
import com.church.cms.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final PasswordResetTokenRepository passwordResetTokenRepository;

    // Gunakan constructor injection yang lebih disarankan
    @Autowired
    public UserService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       PasswordResetTokenRepository passwordResetTokenRepository) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.passwordResetTokenRepository = passwordResetTokenRepository;
    }

    // --- Metode-metode lain yang mungkin Anda miliki untuk User (misalnya register, update profile) ---
    // Contoh:
    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    // Anda bisa menambahkan metode untuk pendaftaran user di sini jika belum ada
    // public User registerUser(User user) { ... }

    // --- Metode Reset Password (pindahkan ke sini) ---

    @Transactional
    public void initiatePasswordReset(ForgotPasswordRequest request) {
        Optional<User> userOptional = userRepository.findByEmail(request.getEmail());
        if (userOptional.isEmpty()) {
            System.out.println("DEBUG: Password reset requested for non-existent email (silently ignoring for security): " + request.getEmail());
            return;
        }

        User user = userOptional.get();

        // Hapus token lama jika ada untuk user ini
        passwordResetTokenRepository.deleteByUser(user);

        // Buat token baru
        String token = UUID.randomUUID().toString();
        LocalDateTime expiryDate = LocalDateTime.now().plusHours(24);

        PasswordResetToken resetToken = new PasswordResetToken(token, user, expiryDate);
        passwordResetTokenRepository.save(resetToken);

        System.out.println("--- PASSWORD RESET INITIATED ---");
        System.out.println("To: " + user.getEmail());
        System.out.println("Reset Token: " + token);
        System.out.println("----------------------------------");
        // Di sini Anda akan mengirim email: emailService.sendPasswordResetEmail(user.getEmail(), token);
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        Optional<PasswordResetToken> tokenOptional = passwordResetTokenRepository.findByToken(request.getToken());

        if (tokenOptional.isEmpty()) {
            throw new RuntimeException("Invalid or expired password reset token.");
        }

        PasswordResetToken resetToken = tokenOptional.get();

        if (resetToken.getExpiryDate().isBefore(LocalDateTime.now())) {
            passwordResetTokenRepository.delete(resetToken);
            throw new RuntimeException("Password reset token has expired.");
        }

        User user = resetToken.getUser();
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        passwordResetTokenRepository.delete(resetToken);
        System.out.println("Password for user " + user.getEmail() + " has been successfully reset.");
    }
}