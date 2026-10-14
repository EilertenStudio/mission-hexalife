package main

import (
	"context"
	"fmt"
	"log"

	"codeberg.org/anaseto/gruid"
	gruidtcell "codeberg.org/anaseto/gruid-tcell"
	"github.com/gdamore/tcell/v2"
)

var level = []string{
	"########################",
	"#@....#...............*#",
	"#.....#................#",
	"#.....#....####........#",
	"#..........#...........#",
	"#..........#...........#",
	"#...####...#.....####..#",
	"#*.........#...........#",
	"#.................*....#",
	"########################",
}

const (
	colorFloor gruid.Color = iota + 1
	colorWall
	colorStar
	colorPlayer
)

type model struct {
	grid      gruid.Grid
	tiles     [][]rune
	player    gruid.Point
	stars     int
	collected int
	message   string
}

func newModel() *model {
	m := &model{grid: gruid.NewGrid(80, 24)}
	m.reset()
	return m
}

func (m *model) reset() {
	m.tiles = make([][]rune, len(level))
	m.stars = 0
	m.collected = 0
	m.message = "Raccogli tutte le stelle."
	for y, row := range level {
		m.tiles[y] = []rune(row)
		for x, tile := range m.tiles[y] {
			switch tile {
			case '@':
				m.player = gruid.Point{X: x, Y: y}
				m.tiles[y][x] = '.'
			case '*':
				m.stars++
			}
		}
	}
}

func (m *model) move(dx, dy int) {
	if m.collected == m.stars {
		return
	}
	next := m.player.Shift(dx, dy)
	if next.Y < 0 || next.Y >= len(m.tiles) || next.X < 0 || next.X >= len(m.tiles[next.Y]) {
		return
	}
	tile := m.tiles[next.Y][next.X]
	if tile == '#' {
		m.message = "Un muro blocca il passaggio."
		return
	}
	m.player = next
	if tile == '*' {
		m.tiles[next.Y][next.X] = '.'
		m.collected++
		m.message = "Stella raccolta!"
		if m.collected == m.stars {
			m.message = "Vittoria! Premi r per ricominciare."
		}
	} else {
		m.message = "Raccogli tutte le stelle."
	}
}

func (m *model) Update(message gruid.Msg) gruid.Effect {
	switch msg := message.(type) {
	case gruid.MsgScreen:
		m.grid = gruid.NewGrid(msg.Width, msg.Height)
	case gruid.MsgKeyDown:
		switch msg.Key {
		case "q", "Q", gruid.KeyEscape:
			return gruid.End()
		case "r", "R":
			m.reset()
		case gruid.KeyArrowUp, "w", "W":
			m.move(0, -1)
		case gruid.KeyArrowDown, "s", "S":
			m.move(0, 1)
		case gruid.KeyArrowLeft, "a", "A":
			m.move(-1, 0)
		case gruid.KeyArrowRight, "d", "D":
			m.move(1, 0)
		}
	case gruid.MsgQuit:
		return gruid.End()
	}
	return nil
}

func (m *model) Draw() gruid.Grid {
	m.grid.Fill(gruid.Cell{Rune: ' '})
	writeLine(m.grid, 0, "Tre stelle — esempio Gruid")
	if size := m.grid.Size(); size.X < len(level[0])+4 || size.Y < len(level)+6 {
		writeLine(m.grid, 2, "Allarga il terminale (minimo 28x16).")
		return m.grid
	}
	writeLine(m.grid, 1, fmt.Sprintf("Stelle: %d/%d", m.collected, m.stars))
	for y, row := range m.tiles {
		for x, tile := range row {
			style := gruid.Style{}
			switch tile {
			case '#':
				style.Fg = colorWall
			case '*':
				style.Fg = colorStar
			case '.':
				style.Fg = colorFloor
			}
			if m.player.X == x && m.player.Y == y {
				tile = '@'
				style.Fg = colorPlayer
			}
			m.grid.Set(gruid.Point{X: x + 2, Y: y + 3}, gruid.Cell{Rune: tile, Style: style})
		}
	}
	writeLine(m.grid, len(level)+4, "Frecce/WASD: muovi   r: ricomincia   q/Esc: esci")
	writeLine(m.grid, len(level)+5, m.message)
	return m.grid
}

func writeLine(grid gruid.Grid, y int, line string) {
	for x, char := range []rune(line) {
		grid.Set(gruid.Point{X: x + 2, Y: y}, gruid.Cell{Rune: char})
	}
}

type defaultStyles struct{}

func (defaultStyles) GetStyle(style gruid.Style) tcell.Style {
	switch style.Fg {
	case colorFloor:
		return tcell.StyleDefault.Foreground(tcell.ColorGray)
	case colorWall:
		return tcell.StyleDefault.Foreground(tcell.ColorWhite)
	case colorStar:
		return tcell.StyleDefault.Foreground(tcell.ColorYellow)
	case colorPlayer:
		return tcell.StyleDefault.Foreground(tcell.ColorGreen)
	default:
		return tcell.StyleDefault
	}
}

func main() {
	app := gruid.NewApp(gruid.AppConfig{
		Driver: gruidtcell.NewDriver(gruidtcell.Config{StyleManager: defaultStyles{}}),
		Model:  newModel(),
	})
	if err := app.Start(context.Background()); err != nil {
		log.Fatal(err)
	}
}
