package cz.fit.cvut.wrzecond.agapesongs.controller

import cz.fit.cvut.wrzecond.agapesongs.dto.*
import cz.fit.cvut.wrzecond.agapesongs.entity.Band
import cz.fit.cvut.wrzecond.agapesongs.service.BandService
import cz.fit.cvut.wrzecond.agapesongs.service.UserService
import org.springframework.web.bind.annotation.*
import javax.servlet.http.HttpServletRequest

@RestController
@RequestMapping("/band")
@Visibility (
    create = VisibilitySettings.NONE,
    update = VisibilitySettings.NONE,
    delete = VisibilitySettings.NONE
)
class BandController (override val service: BandService, userService: UserService)
    : IControllerImpl<Band, BandReadDTO, BandCreateDTO, BandUpdateDTO>(service, userService) {

    @GetMapping("/{id}/playlist")
    fun getPlaylist(@PathVariable id: Int, request: HttpServletRequest)
        = authenticate(request, VisibilitySettings.LOGGED) { user -> service.getPlaylist(id, user) }

    @PutMapping("/{id}/playlist")
    fun putPlaylist(@PathVariable id: Int, @RequestBody playlist: PlaylistDTO, request: HttpServletRequest)
        = authenticate(request, VisibilitySettings.LOGGED) { user -> service.putPlaylist(id, playlist, user) }

}
