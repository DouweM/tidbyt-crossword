load("render.star", "render")
load("animation.star", "animation")
load("random.star", "random")
load("time.star", "time")
load("re.star", "re")
load("humanize.star", "humanize")
load("pixlib/const.star", "const")
load("pixlib/font.star", "font")
load("pixlib/html.star", "html")

URL = "https://www.xwordinfo.com/Crossword?date=%s/%s/%s"

def main(config):
  year = time.now().year

  year = random.number(year - 11, year - 1)
  month = random.number(1, 12)
  day = random.number(1, 28)
  date = time.time(year=year, month=month, day=day)

  response = http.get(URL % (date.month, date.day, date.year))

  if response.status_code != 200:
    fail("Failed to load XWord Info")

  data = response.body()
  doc = html.xpath(data)

  clue_answers = doc.query_all("//div[@class='numclue']/div[position() mod 2 = 0]")
  clue_answers = [
    clue_answer
    for clue_answer in clue_answers
    if valid(clue_answer)
  ]
  clue_answer = clue_answers[random.number(0, len(clue_answers) - 1)]
  clue, answer = clue_answer.split(" : ")

  weekday = humanize.time_format("EEEE", date)

  clue = "Retro-style display that keeps you guessing"
  answer = "TIDBYT"
  weekday = "Sunday"

  title = "%s (%s)" % (weekday, len(answer))

  title_font = "CG-pixel-3x5-mono"
  title_height = font.height(title_font) + 2
  clue_height = const.HEIGHT - title_height

  fps = const.FPS // 3
  delay = 1000 // fps

  return render.Root(
    delay=delay,
    show_full_animation=True,
    child=render.Box(
      child=render.Column(
        expanded=True,
        children=[
          render.Box(
            height=title_height,
            color="#fff",
            child=render.Text(title, font=title_font, color="#000")
          ),
          render.Stack(
            children=[
              render.Box(
                height=clue_height,
                width=const.WIDTH,
                color="#fff",
                child=render_answer(answer)
              ),
              animation.Transformation(
                duration=fps, # A second
                delay=fps * 10, # 10 seconds
                keyframes=[
                  animation.Keyframe(
                    percentage=1.0,
                    transforms=[animation.Translate(0, -clue_height)],
                    curve="ease_in_out",
                  ),
                ],
                child=render.Box(
                  color="#000",
                  child=render.Marquee(
                    scroll_direction="vertical",
                    offset_start=clue_height,
                    height=clue_height,
                    width=const.WIDTH,
                    align="center",
                    child=render.WrappedText(
                      clue,
                      width=const.WIDTH,
                      align="center",
                      font="tom-thumb"
                    )
                  )
                )
              )
            ]
          )
        ]
      )
    )
  )

def valid(clue_answer):
  clue, answer = clue_answer.split(" : ")

  # Too long for the screen, or too short to be interesting
  if len(answer) < 3 or len(answer) > 8:
    return False

  # Usually theme answers
  if "*" in clue:
    return False

  # Referential
  if re.match(r"\d+-(down|across)", clue.lower()):
    return False

  return True

ANSWER_FONT = "CG-pixel-3x5-mono"
CELL_INNER = font.height(ANSWER_FONT) + 2
CELL_OUTER = CELL_INNER + 2

def render_letter(letter):
  return render.Box(
    color="#000",
    height=CELL_OUTER,
    width=CELL_OUTER - 1,
    child=render.Box(
      color="#fff",
      height=CELL_INNER,
      width=CELL_INNER,
      child=render.Padding(
        pad=(1,0,0,0),
        child=render.Text(letter, font=ANSWER_FONT, color="#000")
      )
    )
  )

def render_answer(answer):
  children = [
    render_letter(answer[i])
    for i in range(len(answer))
  ]
  children.append(render.Box(width=1, height=CELL_OUTER, color="#000"))
  return render.Row(children=children)
