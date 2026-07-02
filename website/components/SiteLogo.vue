<template>
  <span class="inline-flex items-center gap-2.5 font-mono text-ink">
    <svg
      viewBox="0 0 1024 1024"
      class="h-6 w-6"
      fill="none"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <defs>
        <linearGradient id="conduitSignal" x1="264" y1="662" x2="760" y2="354" gradientUnits="userSpaceOnUse">
          <stop offset="0" stop-color="#36F9F6" />
          <stop offset="0.48" stop-color="#7AA2F7" />
          <stop offset="1" stop-color="#FF7EDB" />
        </linearGradient>
      </defs>
      <path d="M270 738L510 512L270 286" stroke="#E7F5FF" stroke-width="104" />
      <path d="M524 738L764 512L524 286" stroke="url(#conduitSignal)" stroke-width="104" opacity="0.96" />
    </svg>
    <span class="text-[0.98rem] font-medium tracking-tight">conduit</span>
  </span>
</template>
