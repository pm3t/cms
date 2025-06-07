// src/main/java/com/church/cms/entity/Organization.java
package com.church.cms.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;
import java.util.Set; // Import Set

@Entity
@Table(name = "organizations")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Organization {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(unique = true)
    private String email;

    private String phone;
    private String address;
    private String city;
    private String state;
    private String country;
    private String postalCode;
    private String timezone;
    private String currency;
    private String language;

    @Column(nullable = false)
    private String status = "Active"; // Active, Inactive, Suspended

    @Column(name = "logo_url")
    private String logoUrl;

    @Column(name = "branding_config", columnDefinition = "JSON")
    private String brandingConfig; // Store as JSON string

    @Column(name = "system_preferences", columnDefinition = "JSON")
    private String systemPreferences; // Store as JSON string

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // Relationships
    @OneToMany(mappedBy = "organization", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<User> users;

    @OneToMany(mappedBy = "organization", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<Role> roles;

    // You might add other relationships here as needed, e.g., branches, settings
}