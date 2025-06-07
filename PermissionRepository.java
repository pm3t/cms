// src/main/java/com/church/cms/repository/PermissionRepository.java
package com.church.cms.repository;

import com.church.cms.entity.Organization;
import com.church.cms.entity.Permission;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.Set;

public interface PermissionRepository extends JpaRepository<Permission, Long> {
    Optional<Permission> findByOrganizationAndCode(Organization organization, String code);
    Set<Permission> findByOrganizationAndCodeIn(Organization organization, Set<String> codes);
}