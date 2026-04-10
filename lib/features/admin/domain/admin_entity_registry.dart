import 'package:flutter/material.dart';

import 'admin_entity_definition.dart';

const _idField = AdminFieldDefinition(
  key: 'id',
  label: 'ID',
  nullable: false,
  editable: false,
  width: 90,
);

const _createdAtField = AdminFieldDefinition(
  key: 'created_at',
  label: 'Создано',
  editable: false,
  type: AdminFieldType.dateTime,
  width: 170,
);

const _updatedAtField = AdminFieldDefinition(
  key: 'updated_at',
  label: 'Обновлено',
  editable: false,
  type: AdminFieldType.dateTime,
  width: 170,
);

const adminEntities = <AdminEntityDefinition>[
  AdminEntityDefinition(
    key: 'banners',
    title: 'Баннеры',
    endpoint: '/admin/banners',
    icon: Icons.photo_library_outlined,
    searchFields: ['title'],
    fields: [
      _idField,
      AdminFieldDefinition(
        key: 'title',
        label: 'Заголовок',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'image_url',
        label: 'Ссылка на изображение',
        required: true,
        nullable: false,
        width: 320,
      ),
    ],
    listFieldKeys: ['id', 'title', 'image_url'],
  ),
  AdminEntityDefinition(
    key: 'contact',
    title: 'Контакты',
    endpoint: '/admin/contact',
    icon: Icons.contact_phone_outlined,
    searchFields: ['phone_number', 'email', 'address'],
    fields: [
      _idField,
      AdminFieldDefinition(key: 'phone_number', label: 'Телефон'),
      AdminFieldDefinition(key: 'email', label: 'Email'),
      AdminFieldDefinition(key: 'address', label: 'Адрес', width: 300),
      AdminFieldDefinition(
        key: 'work_schedule',
        label: 'График работы',
        width: 240,
      ),
      AdminFieldDefinition(
        key: 'description',
        label: 'Описание',
        type: AdminFieldType.multiline,
        width: 320,
      ),
    ],
    listFieldKeys: ['id', 'phone_number', 'email', 'address', 'work_schedule'],
  ),
  AdminEntityDefinition(
    key: 'about_page',
    title: 'О нас: страница',
    endpoint: '/admin/about_page',
    icon: Icons.info_outline,
    searchFields: ['mission_description'],
    fields: [
      _idField,
      AdminFieldDefinition(
        key: 'mission_description',
        label: 'Миссия',
        type: AdminFieldType.multiline,
        width: 360,
      ),
    ],
    listFieldKeys: ['id', 'mission_description'],
  ),
  AdminEntityDefinition(
    key: 'about_metrics',
    title: 'О нас: метрики',
    endpoint: '/admin/about_metrics',
    icon: Icons.bar_chart_outlined,
    searchFields: ['metric_label', 'metric_value'],
    fields: [
      _idField,
      //   label: 'Ключ метрики',
      AdminFieldDefinition(
        key: 'metric_key',
        label: 'Ключ метрики',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'metric_value',
        label: 'Значение метрики',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'metric_label',
        label: 'Метка метрики',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'position',
        label: 'Позиция',
        type: AdminFieldType.number,
      ),
    ],
    listFieldKeys: [
      'id',
      'metric_value',
      'metric_label',
      'position',
    ],
  ),
  AdminEntityDefinition(
    key: 'about_sections',
    title: 'О нас: секции',
    endpoint: '/admin/about_sections',
    icon: Icons.segment_outlined,
    searchFields: ['section_key', 'title', 'description'],
    fields: [
      _idField,
      // AdminFieldDefinition(
      //   key: 'section_key',
      //   label: 'Ключ секции',
      //   required: true,
      //   nullable: false,
      // ),
      AdminFieldDefinition(
        key: 'title',
        label: 'Заголовок',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'description',
        label: 'Описание',
        required: true,
        nullable: false,
        type: AdminFieldType.multiline,
        width: 360,
      ),
      AdminFieldDefinition(
        key: 'position',
        label: 'Позиция',
        type: AdminFieldType.number,
      ),
    ],
    listFieldKeys: ['id', 'section_key', 'title', 'description', 'position'],
  ),
  AdminEntityDefinition(
    key: 'partners',
    title: 'Партнеры',
    endpoint: '/admin/partners',
    icon: Icons.handshake_outlined,
    searchFields: ['logo_url'],
    fields: [
      _idField,
      AdminFieldDefinition(
        key: 'logo_url',
        label: 'Логотип (URL)',
        required: true,
        nullable: false,
        width: 360,
      ),
    ],
    listFieldKeys: ['id', 'logo_url'],
  ),
  AdminEntityDefinition(
    key: 'tuning',
    title: 'Тюнинг',
    endpoint: '/admin/tuning',
    icon: Icons.build_circle_outlined,
    searchFields: [
      'brand',
      'model',
      'title',
      'card_description',
      'full_description',
    ],
    fields: [
      _idField,
      AdminFieldDefinition(key: 'brand', label: 'Бренд'),
      AdminFieldDefinition(key: 'model', label: 'Модель'),
      AdminFieldDefinition(
        key: 'title',
        label: 'Заголовок',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'card_image_url',
        label: 'Картинка карточки',
        width: 320,
      ),
      AdminFieldDefinition(
        key: 'full_image_url',
        label: 'Галерея изображений',
        type: AdminFieldType.array,
        width: 360,
      ),
      AdminFieldDefinition(key: 'price', label: 'Цена'),
      AdminFieldDefinition(
        key: 'description',
        label: 'Служебное описание',
        type: AdminFieldType.multiline,
        width: 340,
        editable: false,
      ),
      AdminFieldDefinition(
        key: 'card_description',
        label: 'Описание карточки',
        type: AdminFieldType.multiline,
      ),
      AdminFieldDefinition(
        key: 'full_description',
        label: 'Полное описание',
        type: AdminFieldType.multiline,
      ),
      AdminFieldDefinition(
        key: 'video_image_url',
        label: 'Картинка видео',
        width: 320,
      ),
      AdminFieldDefinition(
        key: 'video_link',
        label: 'Ссылка на видео',
        width: 320,
      ),
      _createdAtField,
      _updatedAtField,
    ],
    listFieldKeys: [
      'id',
      'brand',
      'model',
      'title',
      'card_description',
      'video_link',
      'price',
      'created_at',
      'updated_at',
    ],
  ),
  AdminEntityDefinition(
    key: 'service_offerings',
    title: 'Услуги',
    endpoint: '/admin/service_offerings',
    icon: Icons.miscellaneous_services_outlined,
    searchFields: ['service_type', 'title'],
    fields: [
      _idField,
      AdminFieldDefinition(
        key: 'service_type',
        label: 'Тип услуги',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'title',
        label: 'Заголовок',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'detailed_description',
        label: 'Описание',
        type: AdminFieldType.multiline,
        width: 360,
      ),
      AdminFieldDefinition(
        key: 'gallery_images',
        label: '',
        type: AdminFieldType.array,
        width: 360,
      ),
      AdminFieldDefinition(key: 'price_text', label: 'Текст цены'),
      AdminFieldDefinition(
        key: 'position',
        label: 'Позиция',
        type: AdminFieldType.number,
        editable: false,
      ),
      _createdAtField,
      _updatedAtField,
    ],
    listFieldKeys: ['id', 'service_type', 'title', 'price_text', 'position'],
  ),
  AdminEntityDefinition(
    key: 'privacy_sections',
    title: 'Политика конфиденциальности',
    endpoint: '/admin/privacy_sections',
    icon: Icons.privacy_tip_outlined,
    searchFields: ['title', 'description'],
    fields: [
      _idField,
      AdminFieldDefinition(
        key: 'title',
        label: 'Заголовок',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'description',
        label: 'Описание',
        required: true,
        nullable: false,
        type: AdminFieldType.multiline,
        width: 360,
      ),
      AdminFieldDefinition(
        key: 'position',
        label: 'Позиция',
        type: AdminFieldType.number,
      ),
    ],
    listFieldKeys: ['id', 'title', 'description', 'position'],
  ),
  AdminEntityDefinition(
    key: 'work_post',
    title: 'Посты работ',
    endpoint: '/admin/work_post',
    icon: Icons.work_outline,
    searchFields: ['title_model', 'card_description', 'full_description'],
    fields: [
      _idField,
      AdminFieldDefinition(
        key: 'title_model',
        label: 'Модель/заголовок',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'card_description',
        label: 'Описание',
        type: AdminFieldType.multiline,
      ),
      AdminFieldDefinition(
        key: 'full_description',
        label: 'Полное описание',
        type: AdminFieldType.multiline,
      ),
      AdminFieldDefinition(
        key: 'card_image_url',
        label: 'Изображение URL',
        width: 320,
      ),
      AdminFieldDefinition(key: 'video_link', label: 'Видео URL', width: 320),
      AdminFieldDefinition(
        key: 'work_list',
        label: 'Список работ (JSON/строки)',
        type: AdminFieldType.array,
        width: 360,
      ),
      AdminFieldDefinition(
        key: 'full_image_url',
        label: 'Галерея изображений',
        type: AdminFieldType.array,
        width: 360,
      ),
      _createdAtField,
      _updatedAtField,
    ],
    listFieldKeys: ['id', 'title_model', 'card_description', 'created_at'],
  ),
  AdminEntityDefinition(
    key: 'consultations',
    title: 'Консультации',
    endpoint: '/admin/consultations',
    icon: Icons.support_agent_outlined,
    searchFields: ['first_name', 'last_name', 'phone', 'service_type'],
    fields: [
      _idField,
      AdminFieldDefinition(
        key: 'first_name',
        label: 'Имя',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'last_name',
        label: 'Фамилия',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'phone',
        label: 'Телефон',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(
        key: 'service_type',
        label: 'Тип услуги',
        required: true,
        nullable: false,
      ),
      AdminFieldDefinition(key: 'car_model', label: 'Модель авто'),
      AdminFieldDefinition(
        key: 'preferred_call_time',
        label: 'Удобное время звонка',
      ),
      AdminFieldDefinition(
        key: 'comments',
        label: 'Комментарий',
        type: AdminFieldType.multiline,
      ),
      AdminFieldDefinition(key: 'status', label: 'Статус'),
      _createdAtField,
    ],
    listFieldKeys: [
      'id',
      'first_name',
      'last_name',
      'phone',
      'service_type',
      'status',
      'created_at',
    ],
  ),
];

const embeddedAdminEntityKeys = <String>{'about_metrics', 'about_sections'};

final visibleAdminEntities = adminEntities
    .where((entity) => !embeddedAdminEntityKeys.contains(entity.key))
    .toList(growable: false);

final adminEntityMap = {for (final entity in adminEntities) entity.key: entity};
