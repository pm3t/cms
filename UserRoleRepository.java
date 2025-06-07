// src/main/java/com/church/cms/repository/UserRoleRepository.java
package com.church.cms.repository;

import com.church.cms.entity.UserRole;
import com.church.cms.entity.User;
import com.church.cms.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface UserRoleRepository extends JpaRepository<UserRole, Long> {
    List<UserRole> findByUser(User user);
    Optional<UserRole> findByUserAndRole(User user, Role role);
}