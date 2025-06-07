// src/main/java/com/church/cms/repository/OrganizationRepository.java
package com.church.cms.repository;

import com.church.cms.entity.Organization;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface OrganizationRepository extends JpaRepository<Organization, Long> {
    Optional<Organization> findByName(String name);
    Optional<Organization> findByEmail(String email);
}