package cz.fit.cvut.wrzecond.agapesongs.controller

import cz.fit.cvut.wrzecond.agapesongs.dto.AuthDTO
import cz.fit.cvut.wrzecond.agapesongs.service.AuthService
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/user")
class UserController (private val authService: AuthService) {

    @PostMapping("/login")
    fun authenticate (@RequestBody dto: AuthDTO) = authService.authenticate(dto)

}
