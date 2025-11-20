import { parseStringPromise } from 'xml2js'
import fs from 'fs/promises'
import path from 'path'

export interface Chapter {
    id: string
    title: string
    number: string
}

export interface ParsedContent {
    title: string
    chapters: any[]
}

export async function parseDocBookXML(filePath: string): Promise<ParsedContent> {
    const xmlContent = await fs.readFile(filePath, 'utf-8')

    // Parse with preserveChildrenOrder to maintain mixed content order
    const result = await parseStringPromise(xmlContent, {
        preserveChildrenOrder: true,
        explicitChildren: true,
        charsAsChildren: true
    })
    
    // Collect top-level content in reading order from xml2js's explicitChildren structure.
    // With explicitChildren=true, child elements live in `$$` with `#name` tags.
    const root = (result as any).book || (result as any).article || {}
    const rootChildren = (root.$$ as any[]) || []

    const chapters: any[] = []
    for (const child of rootChildren) {
        const name = child['#name']
        if (name === 'preface' || name === 'chapter' || name === 'section') {
            chapters.push(child)
        }
    }

    // Extract document title from <info><title> using robust fallbacks.
    let title = 'Untitled'
    const info = rootChildren.find((c: any) => c['#name'] === 'info')
    if (info) {
        const titleNode = (info.$$ || []).find((c: any) => c['#name'] === 'title')
        if (titleNode) {
            title = (titleNode._ as string) || (() => {
                const t = (titleNode.$$ || []).find((c: any) => c['#name'] === '__text__')
                return (t && t._) || 'Untitled'
            })()
        }
    }

    return { title, chapters }
}

export async function getAllChapters(): Promise<Chapter[]> {
    const contentDir = process.env.ZIGBOOK_PAGES_DIR ?? 'pages'
    const pagesDir = path.join(process.cwd(), contentDir)
    const files = await fs.readdir(pagesDir)

    const adocFiles = files
        .filter(f => f.endsWith('.adoc') && f.match(/^\d{2}__/))
        .sort()

    return adocFiles.map(file => {
        const match = file.match(/^(\d{2})__(.+)\.adoc$/)
        if (!match) return null

        const [, number, slug] = match
        const title = slug.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase())

        return {
            id: file.replace('.adoc', ''),
            title,
            number
        }
    }).filter(Boolean) as Chapter[]
}

export async function getChapterContent(chapterId: string) {
    // Check if XML version exists
    const contentDir = process.env.ZIGBOOK_PAGES_DIR ?? 'pages'
    const xmlPath = path.join(process.cwd(), contentDir, `${chapterId}.xml`)

    try {
        await fs.access(xmlPath)
        return await parseDocBookXML(xmlPath)
    } catch (err: any) {
        // Fallback: return a single section describing the issue so renderer can display it
        const title = chapterId.replace(/^\d{2}__/, '').replace(/-/g, ' ')
        const message = typeof err?.message === 'string' ? err.message : 'XML解析失败或文件缺失'
        return {
            title,
            chapters: [
                {
                    '#name': 'section',
                    $: { 'xml:id': 'parse-error' },
                    $$: [
                        { '#name': 'title', _: '章节内容解析失败' },
                        { '#name': 'simpara', $$: [ { '#name': '__text__', _: message } ] }
                    ]
                }
            ]
        }
    }
}
