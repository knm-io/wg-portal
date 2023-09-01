package mail

import (
	"bytes"
	"embed"
	"fmt"
	htmlTemplate "html/template"
	"io"
	"text/template"

	"github.com/h44z/wg-portal/internal/domain"
)

//go:embed tpl_files/*
var TemplateFiles embed.FS

type TemplateHandler struct {
	portalUrl     string
	htmlTemplates *htmlTemplate.Template
	textTemplates *template.Template
}

func newTemplateHandler(portalUrl string) (*TemplateHandler, error) {
	htmlTemplateCache, err := htmlTemplate.New("Html").ParseFS(TemplateFiles, "tpl_files/*.gohtml")
	if err != nil {
		return nil, fmt.Errorf("failed to parse html template files: %w", err)
	}

	txtTemplateCache, err := template.New("Txt").ParseFS(TemplateFiles, "tpl_files/*.gotpl")
	if err != nil {
		return nil, fmt.Errorf("failed to parse text template files: %w", err)
	}

	handler := &TemplateHandler{
		portalUrl:     portalUrl,
		htmlTemplates: htmlTemplateCache,
		textTemplates: txtTemplateCache,
	}

	return handler, nil
}

func (c TemplateHandler) GetConfigMail(user *domain.User, link string) (io.Reader, io.Reader, error) {
	var tplBuff bytes.Buffer
	var htmlTplBuff bytes.Buffer

	err := c.textTemplates.ExecuteTemplate(&tplBuff, "mail_with_link.gotpl", map[string]interface{}{
		"User":      user,
		"Link":      link,
		"PortalUrl": c.portalUrl,
	})
	if err != nil {
		return nil, nil, fmt.Errorf("failed to execute template mail_with_link.gotpl: %w", err)
	}

	err = c.htmlTemplates.ExecuteTemplate(&htmlTplBuff, "mail_with_link.gohtml", map[string]interface{}{
		"User":      user,
		"Link":      link,
		"PortalUrl": c.portalUrl,
	})
	if err != nil {
		return nil, nil, fmt.Errorf("failed to execute template mail_with_link.gohtml: %w", err)
	}

	return &tplBuff, &htmlTplBuff, nil
}

func (c TemplateHandler) GetConfigMailWithAttachment(user *domain.User, cfgName, qrName string) (io.Reader, io.Reader, error) {
	var tplBuff bytes.Buffer
	var htmlTplBuff bytes.Buffer

	err := c.textTemplates.ExecuteTemplate(&tplBuff, "mail_with_attachment.gotpl", map[string]interface{}{
		"User":           user,
		"ConfigFileName": cfgName,
		"QrcodePngName":  qrName,
		"PortalUrl":      c.portalUrl,
	})
	if err != nil {
		return nil, nil, fmt.Errorf("failed to execute template mail_with_attachment.gotpl: %w", err)
	}

	err = c.htmlTemplates.ExecuteTemplate(&htmlTplBuff, "mail_with_attachment.gohtml", map[string]interface{}{
		"User":           user,
		"ConfigFileName": cfgName,
		"QrcodePngName":  qrName,
		"PortalUrl":      c.portalUrl,
	})
	if err != nil {
		return nil, nil, fmt.Errorf("failed to execute template mail_with_attachment.gohtml: %w", err)
	}

	return &tplBuff, &htmlTplBuff, nil
}
