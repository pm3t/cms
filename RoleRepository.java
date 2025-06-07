// src/main/java/com/church/cms/repository/RoleRepository.java
package com.church.cms.repository;

import com.church.cms.entity.Organization;
import com.church.cms.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface RoleRepository extends JpaRepository<Role, Long> {
    Optional<Role> findByOrganizationAndName(Organization organization, String name);
    Optional<Role> findByIdAndOrganization(Long id, Organization organization);
}