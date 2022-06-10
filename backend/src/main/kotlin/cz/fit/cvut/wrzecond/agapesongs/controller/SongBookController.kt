package cz.fit.cvut.wrzecond.agapesongs.controller

import cz.fit.cvut.wrzecond.agapesongs.dto.*
import cz.fit.cvut.wrzecond.agapesongs.entity.SongBook
import cz.fit.cvut.wrzecond.agapesongs.service.SongBookService
import cz.fit.cvut.wrzecond.agapesongs.service.UserService
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/songbook")
@Visibility(
    getByID = VisibilitySettings.NONE
)
class SongBookController (override val service: SongBookService, userService: UserService)
    : IControllerImpl<SongBook, SongBookReadDTO, SongBookCreateDTO, SongBookUpdateDTO>(service, userService)
