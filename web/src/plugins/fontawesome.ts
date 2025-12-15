import type { App } from 'vue'
import { library } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import {
  faArrowDownWideShort,
  faCircleHalfStroke,
  faFire,
  faFilterCircleXmark,
  faFont,
  faHeart,
  faMagnifyingGlass,
  faMinus,
  faMoon,
  faSliders,
  faChevronDown,
  faPlus,
  faRightFromBracket,
  faStar,
  faSun,
  faUser,
  faWandMagicSparkles,
  faFilm,
  faClockRotateLeft,
  faHouse,
  faTrashCan,
  faThumbsUp,
} from '@fortawesome/free-solid-svg-icons'
import { faVuejs } from '@fortawesome/free-brands-svg-icons'

library.add(
  faHouse,
  faFire,
  faMagnifyingGlass,
  faHeart,
  faUser,
  faRightFromBracket,
  faMoon,
  faSun,
  faMinus,
  faPlus,
  faFont,
  faArrowDownWideShort,
  faWandMagicSparkles,
  faFilm,
  faStar,
  faClockRotateLeft,
  faCircleHalfStroke,
  faFilterCircleXmark,
  faTrashCan,
  faThumbsUp,
  faSliders,
  faChevronDown,
  faVuejs,
)

export function installFontAwesome(app: App) {
  app.component('FontAwesomeIcon', FontAwesomeIcon)
}
