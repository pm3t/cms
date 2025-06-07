// src/main/java/com/church/cms/entity/User.java
package com.church.cms.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;
import java.util.Set;

import java.util.Objects; // Pastikan ini diimpor
import java.util.HashSet;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(unique = true)
    private String username;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

    private String phone;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "email_verified")
    private boolean emailVerified = false;

    @Column(name = "is_active")
    private boolean isActive = true;

    @Column(name = "require_2fa")
    private boolean require2fa = false;

    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // Relationships
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<UserRole> userRoles  = new HashSet<>();

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        // Penting: Gunakan getId() jika ID Anda tidak langsung diakses atau jika Anda punya @Getter dari Lombok
        // Atau gunakan 'id' langsung jika tidak ada masalah akses
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        // Hanya bandingkan berdasarkan ID. Jika ID belum ada (misal, entitas baru),
        // maka objek akan dianggap sama jika identitasnya sama.
        return id != null && Objects.equals(id, user.id);
    }

    @Override
    public int hashCode() {
        // Hanya gunakan ID untuk hash code. Jika ID belum ada, kembalikan nilai default atau 0.
        // Penting: hashCode dari ID harus konsisten selama hidup objek.
        return Objects.hash(id);
    }
}