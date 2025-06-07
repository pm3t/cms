// src/main/java/com/church/cms/repository/RolePermissionRepository.java
package com.church.cms.repository;

import com.church.cms.entity.RolePermission;
import com.church.cms.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RolePermissionRepository extends JpaRepository<RolePermission, Long> {
    List<RolePermission> findByRole(Role role);
}