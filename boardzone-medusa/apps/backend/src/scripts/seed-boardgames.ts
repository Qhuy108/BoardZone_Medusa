import {
  ContainerRegistrationKeys,
  Modules,
  ProductStatus,
} from '@medusajs/framework/utils'
import type { ExecArgs } from '@medusajs/framework/types'
import {
  createProductCategoriesWorkflow,
  createProductsWorkflow,
  deleteProductsWorkflow,
} from '@medusajs/medusa/core-flows'

export default async function seedBoardGames({ container }: ExecArgs) {
  const logger = container.resolve(ContainerRegistrationKeys.LOGGER)
  const query = container.resolve(ContainerRegistrationKeys.QUERY)

  logger.info('=== BẮT ĐẦU DỌN DẸP & NẠP DỮ LIỆU BOARD GAME CHO BOARDZONE ===')

  // 1. Xóa các sản phẩm quần áo demo cũ
  const { data: existingProducts } = await query.graph({
    entity: 'product',
    fields: ['id', 'title', 'handle'],
  })

  const demoProductIds = existingProducts
    .filter((p) => {
      const h = (p.handle || '').toLowerCase()
      return (
        h.includes('sweatpants') ||
        h.includes('sweatshirt') ||
        h.includes('t-shirt') ||
        h.includes('shorts') ||
        h.startsWith('demo-')
      )
    })
    .map((p) => p.id)

  if (demoProductIds.length > 0) {
    logger.info(`Đang xóa ${demoProductIds.length} sản phẩm quần áo demo cũ...`)
    await deleteProductsWorkflow(container).run({
      input: { ids: demoProductIds },
    })
    logger.info('Đã xóa sạch các sản phẩm quần áo demo!')
  }

  // 2. Lấy thông tin hạ tầng cửa hàng (Sales Channel, Shipping Profile, Currencies)
  const { data: salesChannels } = await query.graph({
    entity: 'sales_channel',
    fields: ['id', 'name'],
  })
  const { data: shippingProfiles } = await query.graph({
    entity: 'shipping_profile',
    fields: ['id'],
  })
  const { data: stores } = await query.graph({
    entity: 'store',
    fields: ['id', 'supported_currencies.currency_code'],
  })

  const salesChannel = salesChannels[0]
  const shippingProfile = shippingProfiles[0]
  const currencyCodes: string[] = (stores[0]?.supported_currencies ?? [])
    .map((c) => c?.currency_code)
    .filter((c): c is string => Boolean(c))

  if (!currencyCodes.includes('eur')) currencyCodes.push('eur')
  if (!currencyCodes.includes('usd')) currencyCodes.push('usd')

  // 3. Tạo Danh mục Board Game
  const { data: existingCategories } = await query.graph({
    entity: 'product_category',
    fields: ['id', 'name', 'handle'],
  })

  const BOARDGAME_CATEGORIES = [
    { name: 'Chiến thuật (Strategy)', handle: 'chien-thuat', description: 'Các tựa game đòi hỏi tư duy chiến lược sâu sắc và tính toán nước đi' },
    { name: 'Party & Nhóm (Party Games)', handle: 'party-game', description: 'Trò chơi vui nhộn, tương tác cao dành cho nhóm bạn đông người' },
    { name: 'Gia đình (Family Games)', handle: 'gia-dinh', description: 'Luật chơi đơn giản, gắn kết các thành viên mọi lứa tuổi' },
    { name: 'Ẩn vai & Suy luận (Social Deduction)', handle: 'an-vai-suy-luan', description: 'Đấu trí tâm lý, tìm kẻ phản bội và bảo vệ phe của mình' },
  ]

  const categoriesToCreate = BOARDGAME_CATEGORIES.filter(
    (cat) => !existingCategories.some((ex) => ex.handle === cat.handle)
  )

  if (categoriesToCreate.length > 0) {
    await createProductCategoriesWorkflow(container).run({
      input: { product_categories: categoriesToCreate },
    })
    logger.info(`Đã tạo ${categoriesToCreate.length} danh mục Board Game mới!`)
  }

  const { data: allCategories } = await query.graph({
    entity: 'product_category',
    fields: ['id', 'handle'],
  })

  const getCatId = (handle: string) => allCategories.find((c) => c.handle === handle)?.id

  // 4. Danh sách Board Game thực tế
  const BOARD_GAMES = [
    {
      title: 'Ma Sói Ultimate (Ultimate Werewolf)',
      handle: 'ma-soi-ultimate',
      subtitle: '5-75 người chơi • 30-90 phút • Tuổi 8+',
      description: 'Trò chơi ma sói kinh điển đỉnh cao dành cho nhóm bạn từ 5 đến 75 người. Đấu trí kịch tính giữa Dân Làng và Ma Sói trong đêm tối huyền bí.',
      thumbnail: 'https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?auto=format&fit=crop&w=800&q=80',
      category_ids: [getCatId('an-vai-suy-luan'), getCatId('party-game')].filter(Boolean) as string[],
      basePrice: 15, // ~189.000 VNĐ
      options: [
        {
          title: 'Phiên bản',
          values: ['Bản Chuẩn Việt Hóa', 'Bản Deluxe Hộp Thiếc'],
        },
      ],
      variants: [
        {
          title: 'Bản Chuẩn Việt Hóa',
          sku: 'BG-MASOI-STD',
          options: { 'Phiên bản': 'Bản Chuẩn Việt Hóa' },
          prices: currencyCodes.map((c) => ({ amount: 15, currency_code: c })),
        },
        {
          title: 'Bản Deluxe Hộp Thiếc',
          sku: 'BG-MASOI-DLX',
          options: { 'Phiên bản': 'Bản Deluxe Hộp Thiếc' },
          prices: currencyCodes.map((c) => ({ amount: 25, currency_code: c })),
        },
      ],
    },
    {
      title: 'Mèo Nổ (Exploding Kittens)',
      handle: 'meo-no-exploding-kittens',
      subtitle: '2-5 người chơi • 15 phút • Tuổi 7+',
      description: 'Phiên bản game bài Nga Roulette phong cách mèo siêu bựa và bất ngờ. Rút phải lá Mèo Nổ sẽ bị loại ngay trừ khi bạn có lá Gỡ Bom!',
      thumbnail: 'https://images.unsplash.com/photo-1606167668584-78701c57f13d?auto=format&fit=crop&w=800&q=80',
      category_ids: [getCatId('party-game'), getCatId('gia-dinh')].filter(Boolean) as string[],
      basePrice: 12,
      options: [
        {
          title: 'Phiên bản',
          values: ['Bản Cơ Bản (Đỏ)', 'Bản Mở Rộng Party Pack'],
        },
      ],
      variants: [
        {
          title: 'Bản Cơ Bản (Đỏ)',
          sku: 'BG-MEONO-STD',
          options: { 'Phiên bản': 'Bản Cơ Bản (Đỏ)' },
          prices: currencyCodes.map((c) => ({ amount: 12, currency_code: c })),
        },
        {
          title: 'Bản Mở Rộng Party Pack',
          sku: 'BG-MEONO-EXP',
          options: { 'Phiên bản': 'Bản Mở Rộng Party Pack' },
          prices: currencyCodes.map((c) => ({ amount: 22, currency_code: c })),
        },
      ],
    },
    {
      title: 'Catan - Người Định Cư Đảo Catan',
      handle: 'catan-dinh-cu-dao-catan',
      subtitle: '3-4 người chơi • 60-120 phút • Tuổi 10+',
      description: 'Tựa game chiến thuật giao thương phát triển hàng đầu thế giới. Thu thập lúa mì, quặng, gạch, gỗ và cừu để xây dựng những khu định cư phồn vinh nhất.',
      thumbnail: 'https://images.unsplash.com/photo-1611195974226-a6a9be9dd763?auto=format&fit=crop&w=800&q=80',
      category_ids: [getCatId('chien-thuat'), getCatId('gia-dinh')].filter(Boolean) as string[],
      basePrice: 45,
      options: [
        {
          title: 'Phiên bản',
          values: ['Bản Gốc Tiếng Việt'],
        },
      ],
      variants: [
        {
          title: 'Bản Gốc Tiếng Việt',
          sku: 'BG-CATAN-VIET',
          options: { 'Phiên bản': 'Bản Gốc Tiếng Việt' },
          prices: currencyCodes.map((c) => ({ amount: 45, currency_code: c })),
        },
      ],
    },
    {
      title: 'Uno Flip!',
      handle: 'uno-flip',
      subtitle: '2-10 người chơi • 30 phút • Tuổi 7+',
      description: 'Phiên bản Uno 2 mặt cực kỳ lật kèo. Khi lá Flip được đánh ra, toàn bộ ván bài chuyển sang Mặt Tối với các lá phạt cực gắt (+5 bài, Bỏ lượt tất cả).',
      thumbnail: 'https://images.unsplash.com/photo-1563941402622-4e7a488bcc57?auto=format&fit=crop&w=800&q=80',
      category_ids: [getCatId('party-game'), getCatId('gia-dinh')].filter(Boolean) as string[],
      basePrice: 8,
      options: [
        {
          title: 'Phiên bản',
          values: ['Hộp Giấy Chuẩn'],
        },
      ],
      variants: [
        {
          title: 'Hộp Giấy Chuẩn',
          sku: 'BG-UNOFLIP-STD',
          options: { 'Phiên bản': 'Hộp Giấy Chuẩn' },
          prices: currencyCodes.map((c) => ({ amount: 8, currency_code: c })),
        },
      ],
    },
    {
      title: 'Splendor (Phục Hưng)',
      handle: 'splendor-phuc-hung',
      subtitle: '2-4 người chơi • 30 phút • Tuổi 10+',
      description: 'Hóa thân thành những thương gia đá quý giàu có thời kỳ Phục Hưng. Khai thác mỏ ngọc, thuê thợ kim hoàn và nhận được sự bảo trợ của giới quý tộc danh giá.',
      thumbnail: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=800&q=80',
      category_ids: [getCatId('chien-thuat')].filter(Boolean) as string[],
      basePrice: 38,
      options: [
        {
          title: 'Phiên bản',
          values: ['Bản Quốc Tế'],
        },
      ],
      variants: [
        {
          title: 'Bản Quốc Tế',
          sku: 'BG-SPLENDOR-INT',
          options: { 'Phiên bản': 'Bản Quốc Tế' },
          prices: currencyCodes.map((c) => ({ amount: 38, currency_code: c })),
        },
      ],
    },
    {
      title: 'Bang! The Dice Game',
      handle: 'bang-the-dice-game',
      subtitle: '3-8 người chơi • 15 phút • Tuổi 8+',
      description: 'Những màn đấu súng nảy lửa đậm chất miền Viễn Tây nước Mỹ. Đổ xí ngầu để bắn kẻ thù, uống bia hồi máu và cẩn thận với mũi tên của người da đỏ!',
      thumbnail: 'https://images.unsplash.com/photo-1522069169874-c58ec4b76be5?auto=format&fit=crop&w=800&q=80',
      category_ids: [getCatId('an-vai-suy-luan'), getCatId('party-game')].filter(Boolean) as string[],
      basePrice: 18,
      options: [
        {
          title: 'Phiên bản',
          values: ['Bản Xí Ngầu Gốc'],
        },
      ],
      variants: [
        {
          title: 'Bản Xí Ngầu Gốc',
          sku: 'BG-BANGDICE-STD',
          options: { 'Phiên bản': 'Bản Xí Ngầu Gốc' },
          prices: currencyCodes.map((c) => ({ amount: 18, currency_code: c })),
        },
      ],
    },
  ]

  // 5. Kiểm tra và Tạo các Board Game mới
  const { data: currentProducts } = await query.graph({
    entity: 'product',
    fields: ['handle'],
  })
  const currentHandles = new Set(currentProducts.map((p) => p.handle))

  const productsPayload = BOARD_GAMES.filter((g) => !currentHandles.has(g.handle)).map((game) => ({
    title: game.title,
    handle: game.handle,
    subtitle: game.subtitle,
    description: game.description,
    status: ProductStatus.PUBLISHED,
    thumbnail: game.thumbnail,
    images: [{ url: game.thumbnail }],
    shipping_profile_id: shippingProfile.id,
    category_ids: game.category_ids,
    sales_channels: [{ id: salesChannel.id }],
    options: game.options,
    variants: game.variants,
  }))

  if (productsPayload.length > 0) {
    logger.info(`Đang tạo ${productsPayload.length} sản phẩm Board Game vào Medusa...`)
    await createProductsWorkflow(container).run({
      input: { products: productsPayload as never },
    })
    logger.info(`Đã nạp thành công ${productsPayload.length} Board Game!`)
  } else {
    logger.info('Các Board Game đã tồn tại đầy đủ trong hệ thống.')
  }

  // 6. Đồng bộ Search Index
  try {
    const search = container.resolve(Modules.SEARCH)
    const { data: allProds } = await query.graph({
      entity: 'product',
      fields: ['id'],
    })
    await search.ingest({
      name: 'product.created',
      data: allProds.map((p) => ({ id: p.id })),
    } as never)
    logger.info(`Đã đồng bộ Search Index cho ${allProds.length} sản phẩm!`)
  } catch (err: unknown) {
    logger.warn('Search ingest skipped: ' + String(err))
  }

  logger.info('=== HOÀN TẤT NẠP DỮ LIỆU BOARD GAME THÀNH CÔNG! ===')
}
