package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	if err := newRouter().Run(":8080"); err != nil {
		log.Fatal(err)
	}
}

func newRouter() *gin.Engine {
	r := gin.New()
	r.GET("/healthz", func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})
	return r
}
